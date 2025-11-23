/**
 * GPU Monitoring for ERNI-KI AI Diagnostics
 * GPU usage monitoring during AI models testing
 *
 * @author Alteon Schultz (Tech Lead)
 * @version 1.0.0
 */
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

class GPUMonitor {
  constructor() {
    this.monitoring = false;
    this.data = [];
    this.interval = null;
    this.outputFile = './test-results/gpu-metrics.json';

    // Create directory for results
    const dir = path.dirname(this.outputFile);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  }

  async checkGPUAvailability() {
    return new Promise(resolve => {
      const nvidia = spawn('nvidia-smi', ['--query-gpu=name', '--format=csv,noheader']);

      let output = '';
      nvidia.stdout.on('data', data => {
        output += data.toString();
      });

      nvidia.on('close', code => {
        if (code === 0 && output.trim()) {
          console.log(`🎮 GPU detected: ${output.trim()}`);
          resolve(true);
        } else {
          console.log('❌ GPU not detected or nvidia-smi unavailable');
          resolve(false);
        }
      });

      nvidia.on('error', () => {
        console.log('❌ Error launching nvidia-smi');
        resolve(false);
      });
    });
  }

  async getGPUMetrics() {
    return new Promise(resolve => {
      const queryFields = [
        'timestamp',
        'name',
        'utilization.gpu',
        'utilization.memory',
        'memory.used',
        'memory.total',
        'temperature.gpu',
        'power.draw',
      ];
      const nvidiaQueryArgs = [
        `--query-gpu=${queryFields.join(',')}`,
        '--format=csv,noheader,nounits',
      ];
      const nvidia = spawn('nvidia-smi', nvidiaQueryArgs);

      let output = '';
      nvidia.stdout.on('data', data => {
        output += data.toString();
      });

      nvidia.on('close', code => {
        if (code === 0) {
          const lines = output.trim().split('\n');
          const metrics = lines.map(line => {
            const [, name, gpuUtil, memUtil, memUsed, memTotal, temp, power] = line.split(', ');
            return {
              timestamp: new Date().toISOString(),
              gpuName: name,
              gpuUtilization: parseInt(gpuUtil) || 0,
              memoryUtilization: parseInt(memUtil) || 0,
              memoryUsed: parseInt(memUsed) || 0,
              memoryTotal: parseInt(memTotal) || 0,
              temperature: parseInt(temp) || 0,
              powerDraw: parseFloat(power) || 0,
            };
          });
          resolve(metrics[0] || null);
        } else {
          resolve(null);
        }
      });

      nvidia.on('error', () => {
        resolve(null);
      });
    });
  }

  async startMonitoring(intervalMs = 2000) {
    if (this.monitoring) {
      console.log('⚠️ Monitoring already running');
      return;
    }

    const gpuAvailable = await this.checkGPUAvailability();
    if (!gpuAvailable) {
      console.log('❌ GPU unavailable for monitoring');
      return false;
    }

    console.log(`🔍 Starting GPU monitoring (interval: ${intervalMs}ms)`);
    this.monitoring = true;
    this.data = [];

    // eslint-disable-next-line no-undef
    this.interval = setInterval(async () => {
      const metrics = await this.getGPUMetrics();
      if (metrics) {
        this.data.push(metrics);

        // Вывод текущих метрик
        const memoryUsage =
          `Memory: ${metrics.memoryUsed}MB/${metrics.memoryTotal}MB ` +
          `(${metrics.memoryUtilization}%)`;
        const usageLineParts = [
          `GPU: ${metrics.gpuUtilization}%`,
          memoryUsage,
          `Temperature: ${metrics.temperature}°C`,
        ];
        console.log(usageLineParts.join(' | '));
      }
    }, intervalMs);

    return true;
  }

  stopMonitoring() {
    if (!this.monitoring) {
      console.log('⚠️ Monitoring not running');
      return;
    }

    console.log('🛑 Stopping GPU monitoring');
    this.monitoring = false;

    if (this.interval) {
      // eslint-disable-next-line no-undef
      clearInterval(this.interval);
      this.interval = null;
    }

    this.saveResults();
  }

  saveResults() {
    if (this.data.length === 0) {
      console.log('📊 No data to save');
      return;
    }

    const report = {
      timestamp: new Date().toISOString(),
      duration: this.data.length * 2, // secondsы (интервал 2с)
      totalSamples: this.data.length,
      metrics: this.data,
      summary: this.calculateSummary(),
    };

    fs.writeFileSync(this.outputFile, JSON.stringify(report, null, 2));
    console.log(`📋 GPU metrics saved: ${this.outputFile}`);

    this.printSummary(report.summary);
  }

  calculateSummary() {
    if (this.data.length === 0) return null;

    const gpuUtils = this.data.map(d => d.gpuUtilization);
    const memUtils = this.data.map(d => d.memoryUtilization);
    const memUsed = this.data.map(d => d.memoryUsed);
    const temps = this.data.map(d => d.temperature);
    const powers = this.data.map(d => d.powerDraw);

    return {
      gpu: {
        min: Math.min(...gpuUtils),
        max: Math.max(...gpuUtils),
        avg: Math.round(gpuUtils.reduce((a, b) => a + b, 0) / gpuUtils.length),
      },
      memory: {
        min: Math.min(...memUtils),
        max: Math.max(...memUtils),
        avg: Math.round(memUtils.reduce((a, b) => a + b, 0) / memUtils.length),
        peakUsedMB: Math.max(...memUsed),
      },
      temperature: {
        min: Math.min(...temps),
        max: Math.max(...temps),
        avg: Math.round(temps.reduce((a, b) => a + b, 0) / temps.length),
      },
      power: {
        min: Math.min(...powers),
        max: Math.max(...powers),
        avg: Math.round((powers.reduce((a, b) => a + b, 0) / powers.length) * 10) / 10,
      },
    };
  }

  printSummary(summary) {
    if (!summary) return;

    console.log('\n' + '='.repeat(50));
    console.log('📊 GPU METRICS SUMMARY');
    console.log('='.repeat(50));
    console.log(
      `🎮 GPU utilization: ${summary.gpu.min}% - ${summary.gpu.max}% ` +
        `(average: ${summary.gpu.avg}%)`,
    );
    console.log(
      `💾 Memory: ${summary.memory.min}% - ${summary.memory.max}% ` +
        `(average: ${summary.memory.avg}%)`,
    );
    console.log(`📈 Peak memory usage: ${summary.memory.peakUsedMB} MB`);
    console.log(
      `🌡️  Temperature: ${summary.temperature.min}°C - ${summary.temperature.max}°C ` +
        `(average: ${summary.temperature.avg}°C)`,
    );
    console.log(
      `⚡ Power consumption: ${summary.power.min}W - ${summary.power.max}W ` +
        `(average: ${summary.power.avg}W)`,
    );
    console.log('='.repeat(50));
  }

  async runStandaloneTest(durationSeconds = 60) {
    console.log(`🚀 Running standalone GPU test for ${durationSeconds} seconds`);

    const started = await this.startMonitoring(1000); // 1 secondsа интервал
    if (!started) {
      return;
    }

    // Имитация нагрузки через Ollama
    console.log('🤖 Sending test request to Ollama...');
    this.sendTestRequest();

    // eslint-disable-next-line no-undef
    setTimeout(() => {
      this.stopMonitoring();
    }, durationSeconds * 1000);
  }

  sendTestRequest() {
    const { spawn } = require('child_process');

    // Отправка запроса к Ollama для создания нагрузки
    const curl = spawn('curl', [
      '-X',
      'POST',
      'http://localhost:11434/api/generate',
      '-H',
      'Content-Type: application/json',
      '-d',
      JSON.stringify({
        model: 'gpt-oss:20b',
        prompt: 'Расскажи подробно о квантовой физике и её применении в современных технологиях.',
        stream: false,
      }),
    ]);

    curl.on('close', code => {
      console.log(`📤 Test request completed (code: ${code})`);
    });

    curl.on('error', error => {
      console.log(`❌ Error sending request: ${error.message}`);
    });
  }
}

// Запуск автономного теста
if (require.main === module) {
  const monitor = new GPUMonitor();

  const duration = process.argv[2] ? parseInt(process.argv[2]) : 60;
  monitor.runStandaloneTest(duration).catch(console.error);

  // Обработка сигналов для корректного завершения
  process.on('SIGINT', () => {
    console.log('\n🛑 Received interrupt signal');
    monitor.stopMonitoring();
    process.exit(0);
  });
}

module.exports = GPUMonitor;

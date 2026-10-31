import { Platform } from "react-native";
import { BleManager, Device } from "react-native-ble-plx";

const HEART_RATE_SERVICE_UUID = "0000180d-0000-1000-8000-00805f9b34fb";
const HEART_RATE_CHAR_UUID = "00002a37-0000-1000-8000-00805f9b34fb";
const BATTERY_SERVICE_UUID = "0000180f-0000-1000-8000-00805f9b34fb";
const BATTERY_CHAR_UUID = "00002a19-0000-1000-8000-00805f9b34fb";
const GENERIC_ACCESS_SERVICE = "00001800-0000-1000-8000-00805f9b34fb";
const DEVICE_NAME_CHAR_UUID = "00002a00-0000-1000-8000-00805f9b34fb";

export type BLEState = "idle" | "scanning" | "connecting" | "connected" | "disconnected" | "unsupported";

export type HRData = {
  bpm: number;
  rr: number[];
  sensorContact: boolean;
};

export type BLEOptions = {
  onHR: (data: HRData) => void;
  onState: (state: BLEState) => void;
  onError: (error: string) => void;
  onDevice?: (name: string) => void;
  onBattery?: (level: number) => void;
};

export class BLEManager {
  private options: BLEOptions;
  private manager: BleManager;
  private device: Device | null = null;
  private state: BLEState = "idle";
  private deviceId: string | null = null;

  constructor(options: BLEOptions) {
    this.options = options;
    this.manager = new BleManager();
  }

  async scan(): Promise<void> {
    if (Platform.OS === "web") {
      this.options.onState("unsupported");
      this.options.onError("BLE nativo não disponível na web");
      return;
    }

    try {
      this.setState("scanning");
      await this.manager.startDeviceScan(
        [HEART_RATE_SERVICE_UUID],
        null,
        (error, scannedDevice) => {
          if (error) {
            this.options.onError(error.message);
            this.setState("idle");
            return;
          }
          if (scannedDevice && scannedDevice.serviceUUIDs?.includes(HEART_RATE_SERVICE_UUID)) {
            this.manager.stopDeviceScan();
            this.connectToDevice(scannedDevice);
          }
        },
      );
    } catch (err) {
      this.setState("idle");
      this.options.onError(err instanceof Error ? err.message : "Erro ao escanear");
    }
  }

  private async connectToDevice(device: Device): Promise<void> {
    try {
      this.setState("connecting");
      this.device = device;
      this.deviceId = device.id;
      const connected = await device.connect();
      await this.manager.discoverAllServicesAndCharacteristicsForDevice(device.id);
      this.setState("connected");
      const name = device.name ?? await this.getDeviceName();
      if (name && this.options.onDevice) this.options.onDevice(name);
      const battery = await this.getBatteryLevel();
      if (battery != null && this.options.onBattery) this.options.onBattery(battery);

      const services = await this.manager.servicesForDevice(device.id);
      for (const service of services) {
        if (service.uuid.toLowerCase() === HEART_RATE_SERVICE_UUID) {
          const characteristics = await this.manager.characteristicsForDevice(device.id, service.uuid);
          for (const char of characteristics) {
            if (char.uuid.toLowerCase() === HEART_RATE_CHAR_UUID) {
              this.manager.monitorCharacteristicForDevice(
                device.id, service.uuid, char.uuid,
                (err, monitoredChar) => {
                  if (err) {
                    this.options.onError(err.message);
                    return;
                  }
                  if (monitoredChar?.value) {
                    const hr = this.parseHR(monitoredChar.value);
                    this.options.onHR(hr);
                  }
                },
              );
            }
          }
        }
      }

      this.manager.onDeviceDisconnected(device.id, () => {
        this.setState("disconnected");
      });
    } catch (err) {
      this.setState("idle");
      this.options.onError(err instanceof Error ? err.message : "Falha ao conectar");
    }
  }

  disconnect(): void {
    if (this.deviceId) {
      this.manager.cancelDeviceConnection(this.deviceId);
    }
    this.device = null;
    this.deviceId = null;
    this.setState("idle");
  }

  async getBatteryLevel(): Promise<number | null> {
    if (!this.deviceId) return null;
    try {
      const char = await this.manager.readCharacteristicForDevice(
        this.deviceId, BATTERY_SERVICE_UUID, BATTERY_CHAR_UUID,
      );
      if (char.value) {
        return parseInt(char.value, 16);
      }
      return null;
    } catch {
      return null;
    }
  }

  async getDeviceName(): Promise<string | null> {
    if (!this.deviceId) return null;
    try {
      const char = await this.manager.readCharacteristicForDevice(
        this.deviceId, GENERIC_ACCESS_SERVICE, DEVICE_NAME_CHAR_UUID,
      );
      if (char.value) {
        const raw = atob(char.value);
        return raw;
      }
      return null;
    } catch {
      return null;
    }
  }

  destroy(): void {
    this.manager.destroy();
  }

  private parseHR(encoded: string): HRData {
    const raw = atob(encoded);
    const bytes = new Uint8Array(raw.length);
    for (let i = 0; i < raw.length; i++) bytes[i] = raw.charCodeAt(i);

    const flags = bytes[0];
    const rate16 = !!(flags & 0x01);
    let bpm = 0;
    if (rate16) {
      bpm = (bytes[2] << 8) | bytes[1];
    } else {
      bpm = bytes[1];
    }

    const sensorContact = !!(flags & 0x06);
    const rr: number[] = [];
    let offset = rate16 ? 3 : 2;
    while (offset + 2 <= bytes.length) {
      rr.push((bytes[offset + 1] << 8) | bytes[offset]);
      offset += 2;
    }

    return { bpm, rr, sensorContact };
  }

  private setState(state: BLEState): void {
    this.state = state;
    this.options.onState(state);
  }
}

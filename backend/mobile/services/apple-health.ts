import AppleHealthKit, {
  HealthKitPermissions,
} from "react-native-health";

const permissions: HealthKitPermissions = {
  permissions: {
    read: [
      AppleHealthKit.Constants.Permissions.HeartRate,
      AppleHealthKit.Constants.Permissions.StepCount,
      AppleHealthKit.Constants.Permissions.DistanceWalkingRunning,
      AppleHealthKit.Constants.Permissions.ActiveEnergyBurned,
      AppleHealthKit.Constants.Permissions.Workout,
      AppleHealthKit.Constants.Permissions.SleepAnalysis,
      AppleHealthKit.Constants.Permissions.RestingHeartRate,
    ],
    write: [
      AppleHealthKit.Constants.Permissions.Workout,
      AppleHealthKit.Constants.Permissions.ActiveEnergyBurned,
    ],
  },
};

export const appleHealth = {
  async isAvailable(): Promise<boolean> {
    return new Promise((resolve) => {
      AppleHealthKit.isAvailable((_err, available) => resolve(available));
    });
  },

  async requestPermissions(): Promise<boolean> {
    return new Promise((resolve) => {
      AppleHealthKit.initHealthKit(permissions, (err) => {
        resolve(!err);
      });
    });
  },

  async getHeartRateSamples(startDate: Date, endDate: Date) {
    return new Promise<any[]>((resolve, reject) => {
      AppleHealthKit.getHeartRateSamples(
        { startDate: startDate.toISOString(), endDate: endDate.toISOString() },
        (err, results) => {
          if (err) reject(err);
          else resolve(results ?? []);
        },
      );
    });
  },

  async getStepCount(startDate: Date, endDate: Date): Promise<number> {
    return new Promise((resolve, reject) => {
      AppleHealthKit.getStepCount(
        { startDate: startDate.toISOString(), endDate: endDate.toISOString() },
        (err, results) => {
          if (err) reject(err);
          else resolve(results?.value ?? 0);
        },
      );
    });
  },

  async getWorkouts(startDate: Date, endDate: Date) {
    return new Promise<any[]>((resolve, reject) => {
      AppleHealthKit.getAnchoredWorkouts(
        { startDate: startDate.toISOString(), endDate: endDate.toISOString() },
        (err, results) => {
          if (err) reject(err);
          else resolve(results?.data ?? []);
        },
      );
    });
  },

  async getActiveEnergyBurned(startDate: Date, endDate: Date) {
    return new Promise<any[]>((resolve, reject) => {
      AppleHealthKit.getActiveEnergyBurned(
        { startDate: startDate.toISOString(), endDate: endDate.toISOString() },
        (err, results) => {
          if (err) reject(err);
          else resolve(results ?? []);
        },
      );
    });
  },

  async saveWorkout(data: {
    activityType: string;
    startDate: string;
    endDate: string;
    energyBurned?: number;
    distance?: number;
  }) {
    return new Promise((resolve, reject) => {
      AppleHealthKit.saveWorkout(data as any, (err, result) => {
        if (err) reject(err);
        else resolve(result);
      });
    });
  },
};

import {
  requestPermission,
  readRecords,
  insertRecords,
  getSdkStatus,
  initialize,
} from "react-native-health-connect";
import { Platform } from "react-native";

export const healthConnect = {
  async isAvailable(): Promise<boolean> {
    if (Platform.OS !== "android") return false;
    try {
      const status = await getSdkStatus();
      return status === 2;
    } catch {
      return false;
    }
  },

  async initialize(): Promise<boolean> {
    try {
      return await initialize();
    } catch {
      return false;
    }
  },

  async requestPermissions(): Promise<boolean> {
    try {
      const permissions = [
        { accessType: "read" as const, recordType: "HeartRate" as const },
        { accessType: "read" as const, recordType: "Steps" as const },
        { accessType: "read" as const, recordType: "Distance" as const },
        { accessType: "read" as const, recordType: "ActiveCaloriesBurned" as const },
        { accessType: "read" as const, recordType: "SleepSession" as const },
        { accessType: "read" as const, recordType: "ExerciseSession" as const },
        { accessType: "write" as const, recordType: "ExerciseSession" as const },
      ];
      await requestPermission(permissions);
      return true;
    } catch {
      return false;
    }
  },

  async getHeartRateSamples(startTime: string, endTime: string) {
    try {
      const result = await readRecords("HeartRate", {
        timeRangeFilter: { operator: "between", startTime, endTime },
      });
      return result.records ?? [];
    } catch {
      return [];
    }
  },

  async getSteps(startTime: string, endTime: string): Promise<number> {
    try {
      const result = await readRecords("Steps", {
        timeRangeFilter: { operator: "between", startTime, endTime },
      });
      return (result.records ?? []).reduce((sum: number, r: any) => sum + (r.count ?? 0), 0);
    } catch {
      return 0;
    }
  },

  async getExerciseSessions(startTime: string, endTime: string) {
    try {
      const result = await readRecords("ExerciseSession", {
        timeRangeFilter: { operator: "between", startTime, endTime },
      });
      return result.records ?? [];
    } catch {
      return [];
    }
  },

  async getSleep(startTime: string, endTime: string) {
    try {
      const result = await readRecords("SleepSession", {
        timeRangeFilter: { operator: "between", startTime, endTime },
      });
      return result.records ?? [];
    } catch {
      return [];
    }
  },

  async saveExerciseSession(data: {
    name: string;
    exerciseType: number;
    startTime: string;
    endTime: string;
    distance?: number;
    energyBurned?: number;
  }) {
    try {
      const ids = await insertRecords([{
        recordType: "ExerciseSession" as const,
        title: data.name,
        exerciseType: data.exerciseType,
        startTime: data.startTime,
        endTime: data.endTime,
        distance: data.distance ? { inMeters: data.distance } : undefined,
        energyBurned: data.energyBurned ? { inKilojoules: data.energyBurned * 4.184 } : undefined,
      } as any]);
      return ids.length > 0;
    } catch {
      return false;
    }
  },

  async getDistance(startTime: string, endTime: string) {
    try {
      const result = await readRecords("Distance", {
        timeRangeFilter: { operator: "between", startTime, endTime },
      });
      return result.records ?? [];
    } catch {
      return [];
    }
  },
};

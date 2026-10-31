import { useState, useRef, useCallback, useEffect } from "react";
import * as Location from "expo-location";
import { Platform } from "react-native";

export type GpsCoordinate = {
  latitude: number;
  longitude: number;
  timestamp: number;
};

export type GpsTrackingState = "idle" | "requesting" | "tracking" | "paused" | "finished";

function haversineDistance(
  lat1: number, lon1: number,
  lat2: number, lon2: number,
): number {
  const R = 6371000;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

export function useGpsTracker() {
  const [state, setState] = useState<GpsTrackingState>("idle");
  const [coords, setCoords] = useState<GpsCoordinate[]>([]);
  const [distance, setDistance] = useState(0);
  const [duration, setDuration] = useState(0);
  const [currentSpeed, setCurrentSpeed] = useState(0);
  const locationSubscription = useRef<Location.LocationSubscription | null>(null);
  const timerInterval = useRef<ReturnType<typeof setInterval> | null>(null);
  const startTime = useRef<number>(0);

  useEffect(() => {
    return () => {
      locationSubscription.current?.remove();
      if (timerInterval.current) clearInterval(timerInterval.current);
    };
  }, []);

  const startTracking = useCallback(async () => {
    setState("requesting");
    const { status } = await Location.requestForegroundPermissionsAsync();
    if (status !== "granted") {
      setState("idle");
      return false;
    }

    const hasBg = await Location.requestBackgroundPermissionsAsync();
    if (!hasBg.granted && Platform.OS === "ios") {
      // Background permission is optional, continue anyway
    }

    setCoords([]);
    setDistance(0);
    setDuration(0);
    setCurrentSpeed(0);
    startTime.current = Date.now();

    const sub = await Location.watchPositionAsync(
      {
        accuracy: Location.Accuracy.High,
        distanceInterval: 5,
        timeInterval: 1000,
      },
      (loc) => {
        const newCoord: GpsCoordinate = {
          latitude: loc.coords.latitude,
          longitude: loc.coords.longitude,
          timestamp: loc.timestamp,
        };
        setCoords((prev) => {
          const updated = [...prev, newCoord];
          if (prev.length > 0) {
            const last = prev[prev.length - 1];
            const d = haversineDistance(
              last.latitude, last.longitude,
              newCoord.latitude, newCoord.longitude,
            );
            setDistance((d2) => d2 + d);
          }
          return updated;
        });
        setCurrentSpeed(loc.coords.speed ?? 0);
      },
    );

    locationSubscription.current = sub;

    timerInterval.current = setInterval(() => {
      setDuration(Math.floor((Date.now() - startTime.current) / 1000));
    }, 1000);

    setState("tracking");
    return true;
  }, []);

  const pauseTracking = useCallback(() => {
    locationSubscription.current?.remove();
    locationSubscription.current = null;
    if (timerInterval.current) clearInterval(timerInterval.current);
    timerInterval.current = null;
    setState("paused");
  }, []);

  const resumeTracking = useCallback(async () => {
    setState("requesting");
    const sub = await Location.watchPositionAsync(
      {
        accuracy: Location.Accuracy.High,
        distanceInterval: 5,
        timeInterval: 1000,
      },
      (loc) => {
        const newCoord: GpsCoordinate = {
          latitude: loc.coords.latitude,
          longitude: loc.coords.longitude,
          timestamp: loc.timestamp,
        };
        setCoords((prev) => {
          const updated = [...prev, newCoord];
          if (prev.length > 0) {
            const last = prev[prev.length - 1];
            const d = haversineDistance(
              last.latitude, last.longitude,
              newCoord.latitude, newCoord.longitude,
            );
            setDistance((d2) => d2 + d);
          }
          return updated;
        });
        setCurrentSpeed(loc.coords.speed ?? 0);
      },
    );
    locationSubscription.current = sub;

    timerInterval.current = setInterval(() => {
      setDuration(Math.floor((Date.now() - startTime.current) / 1000));
    }, 1000);

    setState("tracking");
  }, []);

  const stopTracking = useCallback(() => {
    locationSubscription.current?.remove();
    locationSubscription.current = null;
    if (timerInterval.current) clearInterval(timerInterval.current);
    timerInterval.current = null;
    setState("finished");
  }, []);

  const reset = useCallback(() => {
    setCoords([]);
    setDistance(0);
    setDuration(0);
    setCurrentSpeed(0);
    setState("idle");
  }, []);

  const avgPaceSecPerKm = distance > 0 ? Math.round(duration / (distance / 1000)) : 0;
  const steps = Math.round(distance * 1.3);
  const avgSpeedKmh = duration > 0 ? (distance / 1000) / (duration / 3600) : 0;

  return {
    state,
    coords,
    distance,
    duration,
    currentSpeed,
    avgSpeedKmh,
    avgPaceSecPerKm,
    steps,
    startLat: coords[0]?.latitude ?? null,
    startLng: coords[0]?.longitude ?? null,
    endLat: coords[coords.length - 1]?.latitude ?? null,
    endLng: coords[coords.length - 1]?.longitude ?? null,
    startTracking,
    pauseTracking,
    resumeTracking,
    stopTracking,
    reset,
  };
}

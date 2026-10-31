// src/components/ui/AnimatedBackground.tsx
"use client";

import React from "react";
import { ParallaxField } from "./ParallaxField";

export const AnimatedBackground = React.memo(() => (
  <ParallaxField variant="login" />
));

AnimatedBackground.displayName = "AnimatedBackground";

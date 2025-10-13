# Future Feature Ideas

This document outlines potential major features for future development.

## A) UI/UX Overhaul

The goal is to create a more streamlined, visually consistent, and immersive user experience.

-   **Direct Camera Entry:** The app should open directly into the live camera view, making it feel more like a native camera application.
-   **Unified Visual Style:** Establish a consistent design language across the entire app, inspired by a blend of Apple's native camera UI and a "retro-futurism" aesthetic.
-   **New Settings Pane:** Create a dedicated settings page or pane to house application settings and preferences.
-   **Start Page Redesign:** The existing start page will be replaced by the direct-to-camera experience.

## B) "Hunting" Mode

A new capture mode designed to find the "perfect shot" of a specific object over a set period.

-   **Mode Activation:** The user can enable "Hunting Mode" from the camera interface.
-   **Core Parameters:**
    -   **Target Label:** The user selects a specific object label to "hunt" for from a list of all labels supported by the currently active Core ML model.
    -   **Duration:** The user sets a duration for the hunt (e.g., default of 15 seconds).
-   **Capture Process:**
    -   For the specified duration, the app will continuously capture frames from the camera.
    -   These frames are analyzed in real-time but are not permanently saved to the device at this stage.
-   **Best Shot Selection:**
    -   At the end of the duration, the app automatically selects the top 3 images.
    -   **Initial Criteria:** The primary selection criterion will be the confidence score from the ML model for the target label.
    -   **Future Enhancement:** Later versions could incorporate image quality metrics like sharpness or blur detection to ensure the high-resolution source image is clear.
-   **Results Presentation:**
    -   The 3 best shots are presented to the user.
    -   A user setting could potentially change this to auto-select only the single best shot.
-   **Saving:**
    -   The user can review the selected images and choose the best one(s) to save.
    -   Saved images will be written to the user's photo library in the camera's maximum available resolution.

## For AI Agents

This document provides instructions for AI coding agents on how to work with this repository.

### Project Structure

This project uses `kustomize` to manage Kubernetes manifests. The core manifests are located in the `base` directory, and environment-specific configurations (overlays) are in the `overlays` directory.

- `base/`: Contains the base Kubernetes manifests for each application.
- `overlays/`: Contains kustomize overlays for different environments (e.g., `x86`, `armhf`).
- `install_*.yaml`: These are the final, generated Kubernetes manifest files. **DO NOT EDIT THESE FILES DIRECTLY.**

### Making Changes

1.  **Modify the Base Manifests**: If you need to add a new application or modify an existing one, make your changes in the `base` directory. This usually involves:
    -   Creating a new directory for the application (e.g., `base/new-app/`).
    -   Adding a `kustomization.yaml` to the new application directory.
    -   Adding the new application to the `base/kustomization.yaml`.

2.  **Regenerate the Install Manifests**: After you have made your changes to the base manifests, you **MUST** run the following script to regenerate the final install manifests:

    ```bash
    ./update-manifests.sh
    ```

    This script will update the `install_*.yaml` files in the root of the repository.

### Important Notes

-   **Never edit the `install_*.yaml` files directly.** These files are auto-generated, and your changes will be overwritten the next time the `update-manifests.sh` script is run.
-   Always run `./update-manifests.sh` after making changes to the `base` or `overlays` directories.

# Images Assets

This folder contains all image assets used in the KTV-BTS (Neuschwanstein Castle Ticket Booking System) application.

## Current Images

### `neuschwanstein_castle.png`
- **Description**: Beautiful panoramic view of Neuschwanstein Castle with lake reflection
- **Usage**: Hero section background image on the ticket booking page
- **Dimensions**: Optimized for web display (high resolution)
- **Source**: High-quality stock photo featuring the castle from Marienbrücke viewpoint
- **Format**: PNG
- **Features**: Lossless compression, better quality for detailed images

## Adding New Images

When adding new images to this folder:

1. Use descriptive filenames (e.g., `castle_interior.jpg`, `ticket_icon.png`)
2. Optimize images for web use (reasonable file size while maintaining quality)
3. Update this README with new image descriptions
4. Ensure images are referenced correctly in `pubspec.yaml` under the `assets` section

## Image Guidelines

- **Format**: Prefer JPEG for photos, PNG for icons/graphics with transparency
- **Size**: Optimize for web performance (typically under 500KB)
- **Naming**: Use lowercase with underscores (snake_case)
- **Quality**: Balance between file size and visual quality

## Usage in Code

Images in this folder can be referenced in Flutter code using:

```dart
Image.asset('assets/images/filename.png')
// or
Image.asset('assets/images/filename.jpg')
```

Make sure the `assets/images/` path is included in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/
```

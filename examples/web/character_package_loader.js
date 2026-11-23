/**
 * Runtime adapter for Animation Studio Manager character packages.
 * Browser ES module. No AI, network service, or third-party dependency.
 */
export const PACKAGE_FORMAT = "animation_studio_character_package";
export const PACKAGE_VERSION = 1;

function decodeBase64(base64) {
  const binary = atob(base64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function mimeFromName(name) {
  const extension = String(name).toLowerCase().split(".").pop();
  if (extension === "jpg" || extension === "jpeg") return "image/jpeg";
  if (extension === "webp") return "image/webp";
  return "image/png";
}

export function sampleAnimationClip(clip, timeSeconds, poseKey = "joint_angles") {
  if (!clip || !Array.isArray(clip.keyframes) || clip.keyframes.length === 0) return {};
  const frames = [...clip.keyframes].sort((a, b) => Number(a.time) - Number(b.time));
  const duration = Math.max(0, Number(clip.duration) || 0);
  const time = clip.loop && duration > 0
    ? ((Number(timeSeconds) % duration) + duration) % duration
    : Math.min(Math.max(0, Number(timeSeconds) || 0), duration);

  let left = frames[0];
  let right = frames[frames.length - 1];
  if (time <= Number(frames[0].time)) right = frames[0];
  else if (time >= Number(frames[frames.length - 1].time)) left = right = frames[frames.length - 1];
  else {
    for (let i = 0; i < frames.length - 1; i += 1) {
      if (time >= Number(frames[i].time) && time <= Number(frames[i + 1].time)) {
        left = frames[i];
        right = frames[i + 1];
        break;
      }
    }
  }

  const a = left[poseKey] || {};
  const b = right[poseKey] || {};
  const span = Number(right.time) - Number(left.time);
  const amount = span > 0 ? Math.min(1, Math.max(0, (time - Number(left.time)) / span)) : 0;
  const names = new Set([...Object.keys(a), ...Object.keys(b)]);
  const pose = {};
  for (const name of names) {
    const startValue = a[name] ?? b[name] ?? 0;
    const endValue = b[name] ?? a[name] ?? 0;
    if (Array.isArray(startValue) && Array.isArray(endValue) && startValue.length >= 3 && endValue.length >= 3) {
      pose[name] = [0, 1, 2].map((axis) => Number(startValue[axis]) + (Number(endValue[axis]) - Number(startValue[axis])) * amount);
    } else {
      const start = Number(startValue);
      const end = Number(endValue);
      pose[name] = start + (end - start) * amount;
    }
  }
  return pose;
}

export async function loadCharacterPackage(input) {
  const data = typeof input === "string" ? JSON.parse(input) : input;
  if (!data || data.format !== PACKAGE_FORMAT) throw new Error("Formato de paquete no reconocido.");
  if (Number(data.format_version) !== PACKAGE_VERSION) throw new Error("Versión de paquete no compatible.");
  if (!data.character || typeof data.character !== "object") throw new Error("La ficha del personaje está dañada.");

  const assetUrls = {};
  try {
    for (const [key, encoded] of Object.entries(data.assets || {})) {
      if (typeof encoded !== "string") throw new Error("Recurso gráfico inválido: " + key);
      const bytes = decodeBase64(encoded);
      assetUrls[key] = URL.createObjectURL(new Blob([bytes], { type: mimeFromName(key) }));
    }
  } catch (error) {
    for (const url of Object.values(assetUrls)) URL.revokeObjectURL(url);
    throw error;
  }

  const clips = Array.isArray(data.animation_clips) ? data.animation_clips : [];
  const spatialClips = Array.isArray(data.spatial_animation_clips) ? data.spatial_animation_clips : [];
  return {
    data,
    assetUrls,
    getClip(name) {
      return clips.find((clip) => clip.name === name) || null;
    },
    sampleClip(name, timeSeconds) {
      const clip = clips.find((item) => item.name === name);
      return clip ? sampleAnimationClip(clip, timeSeconds, "joint_angles") : null;
    },
    getSpatialClip(name) {
      return spatialClips.find((clip) => clip.name === name) || null;
    },
    sampleSpatialClip(name, timeSeconds) {
      const clip = spatialClips.find((item) => item.name === name);
      return clip ? sampleAnimationClip(clip, timeSeconds, "bone_rotations_degrees") : null;
    },
    getImageImport() {
      const metadata = data.image_import || {};
      return {
        ...metadata,
        parts: (metadata.parts || []).map((part) => ({
          ...part,
          url: assetUrls[part.asset] || null
        })),
        sourceUrl: assetUrls[metadata.source_asset] || null,
        processedUrl: assetUrls[metadata.processed_asset] || null
      };
    },
    dispose() {
      for (const url of Object.values(assetUrls)) URL.revokeObjectURL(url);
    }
  };
}

export async function loadCharacterPackageFromURL(url, options = {}) {
  const response = await fetch(url, options);
  if (!response.ok) throw new Error("No se pudo cargar el paquete: HTTP " + response.status);
  return loadCharacterPackage(await response.json());
}

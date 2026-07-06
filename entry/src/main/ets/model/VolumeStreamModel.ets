import { audio } from '@kit.AudioKit';

/**
 * View-model for a single controllable volume stream in the watch dashboard.
 *
 * <p>The model carries both platform identifiers and UI state so the page can
 * render stream availability, current level, mute state, and fallback status
 * without making additional audio API calls during layout.</p>
 */
export interface VolumeStreamModel {
  id: string;
  displayOrder: number;
  label: string;
  iconText: string;
  streamUsage: audio.StreamUsage;
  fallbackVolumeType: audio.AudioVolumeType;
  currentLevel: number;
  minLevel: number;
  maxLevel: number;
  percentage: number;
  isAvailable: boolean;
  isMuted?: boolean;
  groupName?: string;
  statusText: string;
}

/**
 * Normalized result returned by stream and group volume lookups.
 *
 * <p>This shape lets the app prefer modern per-stream APIs while falling back
 * to volume group APIs on firmware where a stream is not directly exposed.</p>
 */
export interface VolumeLevelInfo {
  currentLevel: number;
  minLevel: number;
  maxLevel: number;
  percentage: number;
  isAvailable: boolean;
  isMuted?: boolean;
  statusText: string;
}

/**
 * Creates the dashboard's ordered stream definitions.
 *
 * @returns Initial stream models for media, call, ringtone, notification, and alarm.
 */
export function createStreamDefinitions(): VolumeStreamModel[] {
  return [
    {
      id: 'media',
      displayOrder: 0,
      label: 'Media',
      iconText: 'M',
      streamUsage: audio.StreamUsage.STREAM_USAGE_MUSIC,
      fallbackVolumeType: audio.AudioVolumeType.MEDIA,
      currentLevel: 8,
      minLevel: 0,
      maxLevel: 15,
      percentage: 53,
      isAvailable: true,
      groupName: 'Default',
      statusText: 'Ready'
    },
    {
      id: 'call',
      displayOrder: 1,
      label: 'Call',
      iconText: 'C',
      streamUsage: audio.StreamUsage.STREAM_USAGE_VOICE_COMMUNICATION,
      fallbackVolumeType: audio.AudioVolumeType.VOICE_CALL,
      currentLevel: 5,
      minLevel: 0,
      maxLevel: 10,
      percentage: 50,
      isAvailable: true,
      groupName: 'Default',
      statusText: 'Ready'
    },
    {
      id: 'ringtone',
      displayOrder: 2,
      label: 'Ringtone',
      iconText: 'R',
      streamUsage: audio.StreamUsage.STREAM_USAGE_RINGTONE,
      fallbackVolumeType: audio.AudioVolumeType.RINGTONE,
      currentLevel: 6,
      minLevel: 0,
      maxLevel: 15,
      percentage: 40,
      isAvailable: true,
      groupName: 'Default',
      statusText: 'Ready'
    },
    {
      id: 'notification',
      displayOrder: 3,
      label: 'Notify',
      iconText: 'N',
      streamUsage: audio.StreamUsage.STREAM_USAGE_NOTIFICATION,
      fallbackVolumeType: audio.AudioVolumeType.RINGTONE,
      currentLevel: 7,
      minLevel: 0,
      maxLevel: 15,
      percentage: 47,
      isAvailable: true,
      groupName: 'Default',
      statusText: 'Ready'
    },
    {
      id: 'alarm',
      displayOrder: 4,
      label: 'Alarm',
      iconText: 'A',
      streamUsage: audio.StreamUsage.STREAM_USAGE_ALARM,
      fallbackVolumeType: audio.AudioVolumeType.ALARM,
      currentLevel: 9,
      minLevel: 0,
      maxLevel: 15,
      percentage: 60,
      isAvailable: true,
      groupName: 'Default',
      statusText: 'Ready'
    }
  ];
}

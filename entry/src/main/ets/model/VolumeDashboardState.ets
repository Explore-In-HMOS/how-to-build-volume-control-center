import { LoopbackMonitorState, createInitialLoopbackMonitorState } from './LoopbackMonitorState';
import { VolumeStreamModel, createStreamDefinitions } from './VolumeStreamModel';

/**
 * Mutable page state for the circular volume dashboard.
 *
 * <p>The state tracks both the ArcList selection model and transient UI
 * surfaces such as adjustment mode and the system volume panel.</p>
 */
export interface VolumeDashboardState {
  streams: VolumeStreamModel[];
  selectedIndex: number;
  isAdjusting: boolean;
  panelVolumeLevel: number;
  shouldShowPanel: boolean;
  loopbackState: LoopbackMonitorState;
  errorMessage?: ResourceStr;
}

/**
 * Builds the initial dashboard state before live audio values are loaded.
 *
 * @returns Default state used by the page's {@code @State} property.
 */
export function createInitialVolumeDashboardState(): VolumeDashboardState {
  return {
    streams: createStreamDefinitions(),
    selectedIndex: 0,
    isAdjusting: false,
    panelVolumeLevel: 8,
    shouldShowPanel: false,
    loopbackState: createInitialLoopbackMonitorState()
  };
}

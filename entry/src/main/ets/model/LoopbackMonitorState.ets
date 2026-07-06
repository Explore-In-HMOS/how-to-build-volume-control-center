/**
 * UI and runtime state for the optional hardware audio loopback monitor.
 *
 * <p>Monitor Mode is feature-gated because real watch hardware may not expose
 * loopback support. The page uses this state to show support, permission, and
 * enabled status without recreating the loopback object during render.</p>
 */
export interface LoopbackMonitorState {
  isSupported: boolean;
  hasPermission: boolean;
  isCreated: boolean;
  isEnabled: boolean;
  statusText: string;
  monitorVolume: number;
}

/**
 * Creates the default disabled monitor state.
 *
 * @returns Initial monitor state used before support probing completes.
 */
export function createInitialLoopbackMonitorState(): LoopbackMonitorState {
  return {
    isSupported: false,
    hasPermission: false,
    isCreated: false,
    isEnabled: false,
    statusText: 'Checking support',
    monitorVolume: 50
  };
}

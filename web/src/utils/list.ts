import type { EditorState } from '../types/scenes'

export function toArray<T>(value: T[] | Record<string, T> | null | undefined): T[] {
  if (!value) return []
  return Array.isArray(value) ? value : Object.values(value)
}

export function normalizeEditor(state: EditorState): EditorState {
  return { ...state, props: toArray(state.props) }
}

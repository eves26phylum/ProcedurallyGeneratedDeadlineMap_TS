export function createCellExtension<TCell extends object, TData>() {
  const store = new WeakMap<TCell, TData>();

  return {
    get(cell: TCell): TData | undefined {
      return store.get(cell);
    },

    set(cell: TCell, data: TData): void {
      store.set(cell, data);
    },

    has(cell: TCell): boolean {
      return store.has(cell);
    },

    delete(cell: TCell): boolean {
      return store.delete(cell);
    },
    // lazy init
    getOrInit(cell: TCell, init: () => TData): TData {
      if (!store.has(cell)) {
        store.set(cell, init());
      }
      return store.get(cell)!;
    },
  } as const;
}

export type CellExtension<TCell extends object, TData> = ReturnType<
  typeof createCellExtension<TCell, TData>
>;
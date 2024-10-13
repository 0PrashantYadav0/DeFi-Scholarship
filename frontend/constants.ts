export const NETWORK = import.meta.env.VITE_APP_NETWORK ?? "testnet";
export const MODULE_ADDRESS = "0xb90886ecca8e23df9c948d5ed36e77f5a31442a736736dce72aa4ea6a912b7d2";
export const CREATOR_ADDRESS = import.meta.env.VITE_COLLECTION_CREATOR_ADDRESS;
export const COLLECTION_ADDRESS = import.meta.env.VITE_COLLECTION_ADDRESS;
export const IS_DEV = Boolean(import.meta.env.DEV);
export const IS_PROD = Boolean(import.meta.env.PROD);

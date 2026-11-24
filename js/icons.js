// Icônes vectorielles homogènes, silhouette fine de 24px.
const paths={
 home:'<path d="m3 10 9-7 9 7v11H3z"/><path d="M9 21v-8h6v8"/>',
 calendar:'<rect x="3" y="5" width="18" height="16" rx="2"/><path d="M7 2v6M17 2v6M3 10h18"/>',
 tasks:'<path d="M4 6h2l2 2 4-4M13 7h7M4 16h2l2 2 4-4M13 17h7"/>',
 chat:'<path d="M20 11.5a7.5 7.5 0 0 1-7.5 7.5c-1.1 0-2.1-.2-3-.6L4 20l1.6-5.2A7.5 7.5 0 1 1 20 11.5Z"/>',
 files:'<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6M8 13h8M8 17h8"/>',
 clock:'<circle cx="12" cy="12" r="9"/><path d="M12 7v5l4 2"/>',
 settings:'<path d="M12 8.3a3.7 3.7 0 1 0 0 7.4 3.7 3.7 0 0 0 0-7.4Z"/><path d="M19.4 13.7c.08-.55.08-2.85 0-3.4l2-1.6-2-3.4-2.4.95a7.9 7.9 0 0 0-2.5-1.45L14 2.2h-4l-.5 2.6a7.9 7.9 0 0 0-2.5 1.45l-2.4-.95-2 3.4 2 1.6a8.2 8.2 0 0 0 0 3.4l-2 1.6 2 3.4 2.4-.95a7.9 7.9 0 0 0 2.5 1.45l.5 2.6h4l.5-2.6a7.9 7.9 0 0 0 2.5-1.45l2.4.95 2-3.4z"/>',
 bell:'<path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4"/>',
 plus:'<path d="M12 4v16M4 12h16"/>',
 trash:'<path d="M3 6h18M8 6V4h8v2M6 6l1 15h10l1-15M10 10v7M14 10v7"/>',
 phone:'<path d="M22 16.9v3a2 2 0 0 1-2.2 2A19.7 19.7 0 0 1 2.1 4.2 2 2 0 0 1 4.1 2h3a2 2 0 0 1 2 1.7l.5 3a2 2 0 0 1-.6 1.8L7.2 10a16 16 0 0 0 6.8 6.8l1.5-1.8a2 2 0 0 1 1.8-.6l3 .5a2 2 0 0 1 1.7 2Z"/>',
 video:'<rect x="3" y="6" width="14" height="12" rx="2"/><path d="m17 10 4-3v10l-4-3"/>',
 arrow:'<path d="M15 18l-6-6 6-6"/>',
 logout:'<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9"/>',
 copy:'<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/>',
 reply:'<path d="m9 10-5 5 5 5M4 15h10a6 6 0 0 0 0-12"/>',
 share:'<circle cx="18" cy="5" r="2"/><circle cx="6" cy="12" r="2"/><circle cx="18" cy="19" r="2"/><path d="m8 11 8-5M8 13l8 5"/>',
 bookmark:'<path d="M5 4a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v18l-7-5-7 5z"/>'
};
export function icon(n){return `<svg aria-hidden="true" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">${paths[n]||paths.files}</svg>`}

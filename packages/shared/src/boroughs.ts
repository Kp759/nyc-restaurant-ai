export const BOROUGHS = [
  "Manhattan",
  "Brooklyn",
  "Queens",
  "Bronx",
  "Staten Island",
] as const;

export type Borough = (typeof BOROUGHS)[number];

export function isBorough(value: string): value is Borough {
  return (BOROUGHS as readonly string[]).includes(value);
}

/** Curated launch neighborhoods grouped by the MVP phase that introduces them. */
export const NEIGHBORHOODS: ReadonlyArray<{
  name: string;
  borough: Borough;
  mvpPhase: 1 | 2 | 3 | 4;
}> = [
  // --- MVP 1: Manhattan below 59th + Williamsburg + Greenpoint -------------
  { name: "West Village", borough: "Manhattan", mvpPhase: 1 },
  { name: "East Village", borough: "Manhattan", mvpPhase: 1 },
  { name: "Greenwich Village", borough: "Manhattan", mvpPhase: 1 },
  { name: "SoHo", borough: "Manhattan", mvpPhase: 1 },
  { name: "Nolita", borough: "Manhattan", mvpPhase: 1 },
  { name: "Lower East Side", borough: "Manhattan", mvpPhase: 1 },
  { name: "Chinatown", borough: "Manhattan", mvpPhase: 1 },
  { name: "Flatiron", borough: "Manhattan", mvpPhase: 1 },
  { name: "Chelsea", borough: "Manhattan", mvpPhase: 1 },
  { name: "Gramercy", borough: "Manhattan", mvpPhase: 1 },
  { name: "NoMad", borough: "Manhattan", mvpPhase: 1 },
  { name: "Tribeca", borough: "Manhattan", mvpPhase: 1 },
  { name: "Financial District", borough: "Manhattan", mvpPhase: 1 },
  { name: "Hell's Kitchen", borough: "Manhattan", mvpPhase: 1 },
  { name: "Midtown", borough: "Manhattan", mvpPhase: 1 },
  { name: "Williamsburg", borough: "Brooklyn", mvpPhase: 1 },
  { name: "Greenpoint", borough: "Brooklyn", mvpPhase: 1 },

  // --- MVP 2: Brooklyn expansion ------------------------------------------
  { name: "Dumbo", borough: "Brooklyn", mvpPhase: 2 },
  { name: "Brooklyn Heights", borough: "Brooklyn", mvpPhase: 2 },
  { name: "Fort Greene", borough: "Brooklyn", mvpPhase: 2 },
  { name: "Park Slope", borough: "Brooklyn", mvpPhase: 2 },
  { name: "Bushwick", borough: "Brooklyn", mvpPhase: 2 },
  { name: "Bed-Stuy", borough: "Brooklyn", mvpPhase: 2 },

  // --- MVP 3: Queens -------------------------------------------------------
  { name: "Astoria", borough: "Queens", mvpPhase: 3 },
  { name: "Long Island City", borough: "Queens", mvpPhase: 3 },
  { name: "Flushing", borough: "Queens", mvpPhase: 3 },
  { name: "Jackson Heights", borough: "Queens", mvpPhase: 3 },

  // --- MVP 4: Bronx + Staten Island ---------------------------------------
  { name: "South Bronx", borough: "Bronx", mvpPhase: 4 },
  { name: "Arthur Avenue", borough: "Bronx", mvpPhase: 4 },
  { name: "St. George", borough: "Staten Island", mvpPhase: 4 },
];

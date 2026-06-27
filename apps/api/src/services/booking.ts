import type { BookingLink, Restaurant } from "@bitenyc/shared";

/**
 * Builds reservation deep links in BiteNYC's preferred provider order:
 * Resy -> OpenTable -> Tock -> SevenRooms -> Direct website -> Phone.
 * (Live availability is a later phase; for now these are official deep links.)
 */
export function buildBookingLinks(r: Restaurant): BookingLink[] {
  const links: BookingLink[] = [];

  if (r.resy_url) {
    links.push({ provider: "resy", label: "Reserve on Resy", url: r.resy_url });
  }
  if (r.opentable_id) {
    links.push({
      provider: "opentable",
      label: "Reserve on OpenTable",
      url: `https://www.opentable.com/r/${r.opentable_id}`,
    });
  }
  if (r.tock_url) {
    links.push({ provider: "tock", label: "Book on Tock", url: r.tock_url });
  }
  if (r.direct_booking_url) {
    links.push({ provider: "direct", label: "Book Direct", url: r.direct_booking_url });
  }
  if (r.phone) {
    const digits = r.phone.replace(/[^\d+]/g, "");
    if (digits) {
      links.push({ provider: "phone", label: "Call restaurant", url: `tel:${digits}` });
    }
  }

  return links;
}

export function hasReservation(r: Restaurant): boolean {
  return Boolean(r.resy_url || r.opentable_id || r.tock_url || r.direct_booking_url);
}

-- Public phone number for call / Google Maps parity.
alter table restaurants add column if not exists phone text;

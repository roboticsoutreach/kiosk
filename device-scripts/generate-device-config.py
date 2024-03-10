#!/usr/bin/env python3
import argparse
import csv
import json

from pathlib import Path

MASTER_CONFIG = Path(__file__).parent.parent / 'master_config.csv'
GLOBAL_CONFIG = Path(__file__).parent.parent / 'global_config.json'


def generate_config(device, output):
    with open(GLOBAL_CONFIG, 'r') as f:
        global_config = json.load(f)
    all_configs = {}
    with open(MASTER_CONFIG, 'r') as f:
        csv_reader = csv.DictReader(f)
        for row in csv_reader:
            all_configs[row['device'].lower()] = row

    if device.lower() not in all_configs:
        device = 'default'

    with open(output, 'w') as f:
        config = all_configs[device.lower()]
        print(f"Using config for {device}")

        # Apply aliases to URL
        url = config['url']
        for alias, alias_url in [
            ('venue', global_config['venue_compbox']),
            ('public', global_config['public_compbox']),
            ('livestream', (
                "https://www.youtube-nocookie.com/embed/"
                f"{global_config['livestream_url']}?autoplay=1&controls=0&hd=1"
            )),
        ]:
            base_url, url_args = url.split('/', maxsplit=1)
            if alias == base_url:
                url = f"{alias_url}/{url_args}"
                break

        f.writelines([
            f"new_hostname={config['hostname']}\n",
            f"new_kiosk_url={url}\n",
            f"autossh_port={config['autossh_port']}\n",
            f"ntp_server={config['ntp_server']}\n",
            f"autossh_host={global_config['autossh_host']}\n",
            f"compbox_ip={global_config['compbox_ip']}\n",
            f"compbox_host={global_config['venue_compbox']}\n",
            f"public_compbox={global_config['public_compbox']}\n",
        ])


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--device', required=True, help="The MAC address to look for")
    parser.add_argument(
        '--output', required=True,
        help="The file to write environment variables to")
    args = parser.parse_args()

    generate_config(args.device, args.output)


if __name__ == '__main__':
    main()

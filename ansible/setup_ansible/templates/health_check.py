from dopy.manager import DoManager

api_token = "{{ do_token }}"
manager = DoManager(None, api_token, "2")

# List all droplets
droplets = manager.all_active_droplets()
for droplet in droplets:
    print(f"ID: {droplet['id']}, Name: {droplet['name']}, Status: {droplet['status']}")

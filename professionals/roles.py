ADMIN_GROUP = "MUNI Administrators"

# Admins manage professionals only. No user-admin rights (prevents
# privilege escalation) and no delete (deactivate instead).
ADMIN_PERMISSIONS = [
    "view_professional",
    "add_professional",
    "change_professional",
]
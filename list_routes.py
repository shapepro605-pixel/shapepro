import sys
import os
sys.path.append(os.path.join(os.getcwd(), 'backend'))

from app import create_app

app = create_app()
print("-" * 50)
for rule in sorted(app.url_map.iter_rules(), key=lambda r: str(r)):
    methods = ', '.join(rule.methods)
    print(f"{rule.endpoint:30} | {methods:20} | {rule}")
print("-" * 50)

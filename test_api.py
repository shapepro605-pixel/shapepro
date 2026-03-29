import requests

BASE_URL = "http://localhost:5000/api"

def test_api():
    # 1. Register a user
    user_data = {
        "nome": "Test User",
        "email": "test_api@example.com",
        "password": "password123",
        "idade": 25,
        "altura": 180,
        "peso": 80,
        "sexo": "M"
    }
    print("Registering user...")
    r = requests.post(f"{BASE_URL}/auth/register", json=user_data)
    if r.status_code not in [201, 200]:
        print(f"Register failed: {r.status_code} {r.text}")
        # Try login if already exists
        r = requests.post(f"{BASE_URL}/auth/login", json={"email": "test_api@example.com", "password": "password123"})
    
    if r.status_code not in [200, 201]:
        print(f"Auth failed: {r.status_code} {r.text}")
        return

    token = r.json().get('access_token')
    print(f"Token acquired. Calling /plan/progresso...")
    
    headers = {"Authorization": f"Bearer {token}"}
    r = requests.get(f"{BASE_URL}/plan/progresso", headers=headers)
    print(f"Response Status: {r.status_code}")
    if r.status_code == 200:
        print("Success!")
        # print(r.json())
    else:
        print(f"Failed: {r.text}")

if __name__ == "__main__":
    test_api()

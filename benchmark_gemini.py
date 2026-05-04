import requests
import json
import time

api_key = "REMOVED_GEMINI_KEY"
models = [
    "gemini-1.5-flash",
    "gemini-1.5-pro",
    "gemini-1.5-flash-8b",
    "gemini-2.0-flash",
]

prompt = "Bạn là một trợ lý sức khỏe. Hãy cho tôi lời khuyên ngắn gọn về việc giảm cân. Trả lời bằng tiếng Việt."

def test_model(model_name):
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent"
    headers = {
        "Content-Type": "application/json",
        "x-goog-api-key": api_key
    }
    data = {
        "contents": [{
            "parts": [{"text": prompt}]
        }]
    }
    
    start_time = time.time()
    try:
        response = requests.post(url, headers=headers, json=data)
        duration = time.time() - start_time
        
        if response.status_code == 200:
            result = response.json()
            text = result['candidates'][0]['content']['parts'][0]['text']
            return {
                "model": model_name,
                "status": "Success",
                "time": duration,
                "length": len(text),
                "preview": text[:50] + "..."
            }
        else:
            return {
                "model": model_name,
                "status": f"Error {response.status_code}",
                "error": response.text
            }
    except Exception as e:
        return {
            "model": model_name,
            "status": "Exception",
            "error": str(e)
        }

print(f"{'Model':<20} | {'Status':<10} | {'Time (s)':<10} | {'Length':<10}")
print("-" * 60)

for model in models:
    res = test_model(model)
    if res['status'] == "Success":
        print(f"{res['model']:<20} | {res['status']:<10} | {res['time']:<10.2f} | {res['length']:<10}")
    else:
        print(f"{res['model']:<20} | {res['status']:<10} | Error: {res.get('error', 'Unknown')[:50]}...")

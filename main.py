import os
from fastapi import FastAPI, Request, Depends, Form
from fastapi.responses import RedirectResponse, HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
import httpx
from itsdangerous import URLSafeSerializer

app = FastAPI()
templates = Jinja2Templates(directory="templates")
app.mount("/static", StaticFiles(directory="static"), name="static")

VERCEL_CLIENT_ID = os.getenv("VERCEL_CLIENT_ID")
VERCEL_CLIENT_SECRET = os.getenv("VERCEL_CLIENT_SECRET")
BASE_URL = os.getenv("BASE_URL")
SECRET_KEY = os.getenv("SECRET_KEY")
serializer = URLSafeSerializer(SECRET_KEY)

@app.get("/login")
def login():
    url = f"https://vercel.com/oauth/authorize?client_id={VERCEL_CLIENT_ID}&scope=read&redirect_uri={BASE_URL}/auth/callback"
    return RedirectResponse(url)

@app.get("/auth/callback")
async def auth_callback(code: str):
    async with httpx.AsyncClient() as client:
        resp = await client.post("https://api.vercel.com/v2/oauth/access_token", data={
            "client_id": VERCEL_CLIENT_ID,
            "client_secret": VERCEL_CLIENT_SECRET,
            "code": code,
            "redirect_uri": f"{BASE_URL}/auth/callback"
        })
        data = resp.json()
        access_token = data.get("access_token")
        if not access_token:
            return HTMLResponse("Error logging in", status_code=400)
        response = RedirectResponse("/projects")
        response.set_cookie("token", serializer.dumps(access_token), httponly=True)
        return response

async def get_token(request: Request):
    token_cookie = request.cookies.get("token")
    if not token_cookie:
        return None
    return serializer.loads(token_cookie)

@app.get("/projects")
async def projects(request: Request, token=Depends(get_token)):
    if not token:
        return RedirectResponse("/login")
    async with httpx.AsyncClient() as client:
        resp = await client.get("https://api.vercel.com/v6/projects", headers={"Authorization": f"Bearer {token}"})
        projects = resp.json().get("projects", [])
    return templates.TemplateResponse("projects.html", {"request": request, "projects": projects})

@app.post("/select_project")
def select_project(request: Request, project_id: str = Form(...)):
    response = RedirectResponse("/dashboard")
    response.set_cookie("project_id", project_id, httponly=True)
    return response

@app.get("/dashboard")
async def dashboard(request: Request):
    project_id = request.cookies.get("project_id")
    if not project_id:
        return RedirectResponse("/projects")
    stats = {"total": 1234, "paths": ["/", "/blog", "/about"]}  # placeholder stats
    return templates.TemplateResponse("dashboard.html", {"request": request, "stats": stats})

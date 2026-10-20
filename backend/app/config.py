from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+psycopg2://trustfarm:trustfarm@localhost:5432/trustfarm"
    ai_url: str = "http://localhost:8001"
    jwt_secret: str = "dev-secret-change-me"
    jwt_hours: int = 12
    admin_email: str = "admin@trustfarm.local"
    admin_password: str = "change-me-now"
    mqtt_host: str = "localhost"
    mqtt_port: int = 1883
    mqtt_user: str = "backend"
    mqtt_password: str = ""
    pump_w: float = 50
    soc_critical: float = 20
    soc_conserve: float = 40


settings = Settings()

from pydantic import BaseModel

class Employee(BaseModel):
    id: int = None
    name: str
    age: int
    email: str
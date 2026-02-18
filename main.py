from fastapi import FastAPI
from employee import Employee

app = FastAPI()

list_of_employees = [Employee(id=1, name="John Doe", age=30, email="john.doe@example.com")
                     , Employee(id=2, name="Jane Smith", age=25, email="jane.smith@example.com"),
                     Employee(id=3, name="Bob Johnson", age=40, email="bob.johnson@example.com"),
                     Employee(id=4, name="Alice Brown", age=35, email="alice.brown@example.com"),
                     Employee(id=5, name="Charlie Davis", age=28, email="charlie.davis@example.com"),
                     Employee(id=6, name="Emily Wilson", age=32, email="emily.wilson@example.com"),
                     Employee(id=7, name="David Lee", age=45, email="david.lee@test.com"),
                        Employee(id=8, name="Sarah Miller", age=29, email="sarah.miller@example.com"),
                     ]


@app.get("/")
def read_root():
    return {"message": "Welcome to the Employee Management System API"}

@app.get("/employees")
def get_employees():
    return list_of_employees

@app.get("/employees/{employee_id}")
def get_employee(employee_id: int):
    for employee in list_of_employees:
        if employee.id == employee_id:
            return employee
    return {"message": "Employee not found"}

@app.post("/employees")
def add_employee(employee: Employee):
    employee.id = len(list_of_employees) + 1
    list_of_employees.append(employee)
    return employee

@app.put("/employees/{employee_id}")
def update_employee(employee_id: int, updated_employee: Employee):
    for index, employee in enumerate(list_of_employees):
        if employee.id == employee_id:
            list_of_employees[index] = updated_employee
            return updated_employee
    return {"message": "Employee not found"}

@app.delete("/employees/{employee_id}")
def delete_employee(employee_id: int):
    for index, employee in enumerate(list_of_employees):
        if employee.id == employee_id:
            del list_of_employees[index]
            return {"message": "Employee deleted"}
    return {"message": "Employee not found"}
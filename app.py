from fastapi import FastAPI
import pickle
from pydantic import BaseModel
from fastapi import HTTPException
from mangum import Mangum
import os
from dotenv import load_dotenv
import boto3

load_dotenv()

s3=boto3.client("s3")
LOCAL_MODEL_PATH = "/tmp/ml_pipiline.pkl"

s3.download_file(
    os.getenv("S3_BUCKET_NAME"), 
    os.getenv("S3_MODEL_FILE"), 
    LOCAL_MODEL_PATH
)

with open("/tmp/ml_pipiline.pkl", "rb") as file:
    model = pickle.load(file)

app=FastAPI()

class Input(BaseModel):
    pclass: int
    sex: str
    age: int
    familysize: int
    fare: float

@app.get('/home')
def home():
    return {"message": "welcome to the app"}


@app.post('/predict2')
def predict(data: Input):
    pclass, sex, age, famsize, fare=data.pclass, data.sex, data.age, data.familysize, data.fare
    
    if sex not in ["male", "man", "female", "woman"]:
        raise HTTPException(
            status_code=400,
            detail="sex must be male or female"
        )
    sex = data.sex.lower()
    if sex in ["male", "man"]:
        sex_encoded = 0
    else:
        sex_encoded = 1

    if famsize<=1: 
        isAlone=1
    else: isAlone=0

    pred=model.predict([[pclass, sex_encoded, age, fare, famsize, isAlone]])
    pred = int(pred[0])
    if pred==1: 
        return {
            "prediction": int(pred),
            "result": "congrats you survived"}
    else: 
        return {"prediction": int(pred),
                  "result": "you died"}
    
lambda_handler=Mangum(app)
FROM public.ecr.aws/lambda/python:3.11

WORKDIR /var/task

COPY requirements.txt .

RUN pip install --upgrade pip setuptools wheel

RUN pip install \
    --no-cache-dir \
    --only-binary=:all: \
    -r requirements.txt

COPY . .

CMD ["app.lambda_handler"]
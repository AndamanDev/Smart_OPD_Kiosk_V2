from ultralytics import YOLO

model = YOLO("yolov8n.pt")

model.train(
    data="D-IDCardDetection-1/data.yaml",
    epochs=50,
    imgsz=640
)
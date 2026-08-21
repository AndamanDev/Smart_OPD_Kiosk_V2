from roboflow import Roboflow
rf = Roboflow(api_key="rrJJSuGbWID5q9zKXm6K")
project = rf.workspace("pluems-workspace").project("d-idcarddetection-ev4qr")
version = project.version(1)
dataset = version.download("yolov8")
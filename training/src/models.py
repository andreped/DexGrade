from keras.applications import MobileNetV3Small, mobilenet_v3
from keras.layers import Dense, GlobalAveragePooling2D, Input, Lambda
from keras.models import Model


def create_model(nb_classes: int):
    input_tensor = Input(shape=(224, 224, 3))
    x = Lambda(mobilenet_v3.preprocess_input)(input_tensor)
    base_model = MobileNetV3Small(input_tensor=x, include_top=False, weights='imagenet')
    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = Dense(128, activation='relu')(x)
    predictions = Dense(nb_classes, activation='softmax')(x)
    return Model(inputs=input_tensor, outputs=predictions)

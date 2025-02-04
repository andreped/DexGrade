import tensorflow as tf
from tensorflow.keras.preprocessing import image_dataset_from_directory
import os
import random
import shutil

from .src.models import create_model


def main():

    # Paths
    dataset_path = '/path/to/psa_dataset'
    train_path = '/path/to/train'
    test_path = '/path/to/test'

    # Create train and test directories
    os.makedirs(train_path, exist_ok=True)
    os.makedirs(test_path, exist_ok=True)

    # Split data into train and test sets
    for label in os.listdir(dataset_path):
        label_path = os.path.join(dataset_path, label)
        if os.path.isdir(label_path):
            images = os.listdir(label_path)
            random.shuffle(images)
            test_images = images[:5]
            train_images = images[5:]
            
            os.makedirs(os.path.join(train_path, label), exist_ok=True)
            os.makedirs(os.path.join(test_path, label), exist_ok=True)
            
            for img in test_images:
                shutil.copy(os.path.join(label_path, img), os.path.join(test_path, label, img))
            for img in train_images:
                shutil.copy(os.path.join(label_path, img), os.path.join(train_path, label, img))

    # Load datasets
    train_dataset = image_dataset_from_directory(train_path, image_size=(224, 224), batch_size=32)
    test_dataset = image_dataset_from_directory(test_path, image_size=(224, 224), batch_size=32)
    val_dataset = train_dataset.take(20)
    train_dataset = train_dataset.skip(20)

    # Define the model
    model = create_model(nb_classes=10)

    # Compile the model
    model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])

    # Train the model
    model.fit(train_dataset, validation_data=val_dataset, epochs=10)

    # Evaluate the model
    loss, accuracy = model.evaluate(test_dataset)
    print(f'Test accuracy: {accuracy}')


if __name__ == '__main__':
    main()

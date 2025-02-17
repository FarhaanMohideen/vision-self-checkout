# Pipeline Run

## Prerequisites: 
Pipeline setup needs to be done first, pipeline setup documentation be found [HERE](./pipelinesetup.md)

## Run camera simulator

```
./camera-simulator/camera-simulator.sh
``` 

```
docker ps --format 'table{{.Image}}\t{{.Status}}\t{{.Names}}'
```

!!! success
    Your output is as follows:

    | IMAGE                                              | STATUS                   | NAMES             |
    | -------------------------------------------------- | ------------------------ |-------------------|
    | openvino/ubuntu20_data_runtime:2021.4.2            | Up 11 seconds            | simulator_docker  |
    | openvino/ubuntu20_data_runtime:2021.4.2            | Up 11 seconds            | simulator_docker2 |
    | aler9/rtsp-simple-server                           | Up 13 seconds            | camera-simulator  |

Note: there could be multiple containers with IMAGE "openvino/ubuntu20_data_runtime:2021.4.2", depending on number of sample-media video file you have.

!!! failure
    If you do not see all of the above docker containers, look through the consol output for errors. Sometimes dependencies fail to resolve and must be run again. Address obvious issues. To try again, repeat step 3.


## Run pipeline with different input source(inputsrc) types
Use docker-run.sh to run the pipeline

### option 1 to run with simuated camera:

```
./docker-run.sh --platform core|xeon|dgpu.x --inputsrc rtsp://127.0.0.1:8554/camera_0
```  

### option 2 to run with USB Camera:

```
./docker-run.sh --platform core|xeon|dgpu.x --inputsrc /dev/video0
``` 

### option 3 to run with RealSense Camera(serial number input):

```
./docker-run.sh --platform core|xeon|dgpu.x --inputsrc serial_number --realsense_enabled

```
Obtaining RealSense camera serial number: [How_to_get_serial_number](./camera_serial_number.md)
### option 4 to run with video file input:

```
./docker-run.sh --platform core|xeon|dgpu.x --inputsrc file:my_video_file.mp4
``` 


## Check for pipeline run success 

Make sure the command was successful. To do so, run:

```
docker ps --format 'table{{.Image}}\t{{.Status}}\t{{.Names}}'
```

!!! success
    Your output for Core is as follows:

    | IMAGE                                              | STATUS                   | NAMES                 |
    | -------------------------------------------------- | ------------------------ |-----------------------|
    | sco-soc:2.0                                        | Up 9 seconds             | vision-self-checkout0 |

    Your output for DGPU is as follows:
    | IMAGE                                              | STATUS                   | NAMES                 |
    | -------------------------------------------------- | ------------------------ |-----------------------|
    | sco-dgpu:2.0                                       | Up 9 seconds             | vision-self-checkout0 |

!!! failure
    If you do not see above docker container, look through the consol output for errors. Sometimes dependencies fail to resolve and must be run again. Address obvious issues. To try again, repeat step 4.


## Optional parameters
The optional parameters you can apply to the docker-run.sh input, just note that they will affect the performance of pipeline run.

### `--classification_disabled`
To disable classification process of image extraction when applying model, default is NOT disabling classification if this is not provided as input to docker-run.sh

### `--ocr_disabled`
To disable Optical character recognition when applying model, default is NOT disabling ocr if this is not provided as input to docker-run.sh

### `--ocr`
To provide Optical character recogntion frame internal value such as `--ocr 5`, default value is 5

### `--barcode_disabled`
To disable barcode detection when applying model, default is NOT disabling barcode detection if this is not provided as input to docker-run.sh

### `--realsense_enabled`
TO use realsense camera and to provide realsense camera 12 digit serial number as inputsrc to the docker-run.sh script

### `--barcode`
To provide barcode detection frame internal value such as `--barcode 5`, default value is 5

### `--color-width`
Realsense camera color related property, to apply realsense camera color width, which will overwrite the default value of realsense gstreamer; if it's not provided, it will use the default value from realsense gstreamer; make sure to look up to your realsense camera's color capability using `rs-enumerate-devices`

### `--color-height`
Realsense camera color related property, to apply realsense camera color height, which will overwrite the default value of realsense gstreamer; if it's not provided, it will use the default value from realsense gstreamer; make sure to look up to your realsense camera's color capability using `rs-enumerate-devices`

### `--color-framerate`
Realsense camera color related property, to apply realsense camera color framerate, which will overwrite the default value of realsense gstreamer; if it's not provided, it will use the default value from realsense gstreamer; make sure to look up to your realsense camera's color capability using `rs-enumerate-devices`

## RealSense option pipeline run example:

`./docker-run.sh --platform core --inputsrc serial_number --realsense_enabled --color-width 1920 --color-height 1080 --color-framerate 15`


## Sample output in results/r0.jsonl:
```
{"resolution":{"height":1080,"width":1920},"timestamp":1087436877}
{"resolution":{"height":1080,"width":1920},"timestamp":1099074821}
{"resolution":{"height":1080,"width":1920},"timestamp":1151501119}
{"resolution":{"height":1080,"width":1920},"timestamp":3975573215}
{"resolution":{"height":1080,"width":1920},"timestamp":3986134627}
{"resolution":{"height":1080,"width":1920},"timestamp":4038743185}
{"resolution":{"height":1080,"width":1920},"timestamp":4047353514}
{"resolution":{"height":1080,"width":1920},"timestamp":4105882925}
{"resolution":{"height":1080,"width":1920},"timestamp":4173170063}
{"resolution":{"height":1080,"width":1920},"timestamp":4240359869}
...
```
## Sample output in results/pipeline0.log:
```
27.34
27.34
27.60
27.60
28.30
28.30
28.61
28.61
28.48
28.48
...
```

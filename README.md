# Bluetooth Remote Control Car  

## Team member:  
107062361 許珉濠， 107062233 黃瀅嘉  

## Project Description:  
這次project的目標是利用FPGA來實作出一臺可以用藍芽操控的遙控車，再加上偵測碰撞的能力，所以具備以下功能：  
#### (一) 處理bluetooth傳入的訊號  
#### (二) 控制馬達  
#### (三) 處理超音波感測器的訊號  
#### (四) 如果有物體過於接近,發出聲音來警示  

## Main Function:  
#### (一) Bluetooth:  
我們使用了 hc-06 的藍芽模組，手機可以用藍芽連上去，然後它會將手機app傳輸的訊號利用UART的形式傳入FPGA。  
#### (二) Motor:  
我們使用了 L298N 的模組來驅動馬達。  
#### (三) Ultrasonic sensor:  
我們使用 HC-SR04 的超音波感測器來偵測物體和車子之間的距離。  
#### (四) Audio  
#### (五) Additional feature:  
#### Seven segment:
可以依據switch的切換來顯示 手機app傳入的訊號數值 或是 ultrasonic module傳入與物體之間的距離。  
#### Switch:
除了利用手機下載的遙控器app，我們也可以透過switch來操控車子。  
#### Led:
Led會根據當前的行駛方向來亮燈。  

## Demo:
<img width="3024" height="4032" alt="IMG_0332" src="https://github.com/user-attachments/assets/f596975c-1663-489e-a458-bf85c90352fd" />  

<img width="4032" height="3024" alt="IMG_0333" src="https://github.com/user-attachments/assets/ad4b1583-a6d5-43e5-bd90-bc969aecd53e" />

https://github.com/user-attachments/assets/2adeb1fb-dd8a-42d6-8952-d6019d8a67a7

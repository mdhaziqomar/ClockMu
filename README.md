## ClockMu

An alarm clock app for **[Mustard OS(muOS)](https://muos.dev/): 2601.1 Funky Jacaranda** on the **[Anbernic RG35XX Pro](https://anbernic.com/products/rg35xxpro)**.  
Built with LÖVE2D, matching the muOS Mustard colour theme.

Drew inspiration from [BitMuos](https://github.com/nvcuong1312/bltMuos) by [nvcuong1312](https://github.com/nvcuong1312).

<img width="640" height="480" alt="Main Screen" src="https://github.com/user-attachments/assets/f20cbf92-68a0-4413-8677-75872a1069dd" />

### 🚀 Features  
- Set and manage multiple alarms (max configurable)  
- Repeat options: daily, weekly (specific days), or once  
- Snooze with custom durations (per alarm)  
- Preset time picker (every 15 minutes)  
- Configurable colour themes and sound  
- Data persistence across reboots  

### 📥 Installation  
1. Download the latest release from [GitHub Releases](https://github.com/mdhaziqomar/ClockMu/releases).  
2. Follow the installation instructions in the documentation.  

### 🎮 Controls  

#### Main Screen  
| Button | Action |
|--------|--------|
| D-pad Up/Down | Navigate alarm list |
| **A** | Edit selected alarm |
| **X** | Toggle alarm on/off |
| **Y** | Add new alarm |
| **L1** | Delete selected alarm |
| **B** | Quit |

#### Edit Alarm

<img width="640" height="480" alt="Edit Alarm" src="https://github.com/user-attachments/assets/3588e73f-14de-4fd9-9de6-1929ad093cdd" />


| Button | Action |
|--------|--------|
| Up/Down | Move between fields (Hour / Minute / Label / Repeat / Snooze / Enabled) |
| Left/Right | Change value (±1 for hour/min, cycle options for others) |
| **L1 / R1** | Change minute by ±10 |
| **A** (on Repeat field) | Toggle selected day on/off |
| **X** (on Repeat field) | Clear all days → set to "Once" |
| **Y** | Open preset time picker (every 15 min) |
| **A** (other fields) | Save alarm |
| **B** | Cancel |

<img width="640" height="480" alt="Keyboard" src="https://github.com/user-attachments/assets/fd8f3256-7145-45cc-89b9-a87eae28d600" />

#### Preset Time Picker  
| Button | Action |
|--------|--------|
| Up/Down | Scroll times |
| Left/Right | Jump page |
| **A** | Select time |
| **B** | Cancel |

#### When Alarm Rings  

<img width="640" height="480" alt="Alert" src="https://github.com/user-attachments/assets/a23ddbfa-3645-41f5-b1fa-833c9d0de528" />

| Button | Action |
|--------|--------|
| **A** | Snooze (5 / 10 / 15 min — per alarm setting) |
| **B** | Dismiss |

### 💾 Data Persistence  

Alarms are saved to `data/alarms.txt` automatically whenever you add, edit, delete, or dismiss an alarm. They persist across reboots.

### 📝 Notes  

- Alarms only fire while ClockMu is running (muOS foreground app).  
- One-shot alarms (Repeat: Once) disable themselves after firing.  
- Snoozed alarms resume ringing after the chosen snooze duration.  

### 📚 Available Themes:  
- Bloody Red
<img width="640" height="480" alt="Bloody Red Theme" src="https://github.com/user-attachments/assets/ac3266be-8f14-422f-a66d-714d422908c6" />

- Forest Green
<img width="640" height="480" alt="Forest Green Theme" src="https://github.com/user-attachments/assets/60808220-5e4b-4c50-8254-a30426a2b306" />

- Funky Purple
<img width="640" height="480" alt="Funky Purple Theme" src="https://github.com/user-attachments/assets/fb0dc343-731e-47be-8a01-15c8a417faae" />

- Intense Orange
<img width="640" height="480" alt="Intense Orange Theme" src="https://github.com/user-attachments/assets/db1436bb-c2fe-449f-b68e-14220fc763f4" />

- Midnight Black
<img width="640" height="480" alt="Midnight Black Theme" src="https://github.com/user-attachments/assets/1a4f3172-f047-413a-ae09-96bb09dafec4" />

- Ocean Blue
<img width="640" height="480" alt="Ocean Blue Theme" src="https://github.com/user-attachments/assets/4dc2f7f2-ad23-435c-ad97-cda530dda675" />

- Yoga White
<img width="640" height="480" alt="Yoga White Theme" src="https://github.com/user-attachments/assets/c3aa5005-c077-492c-a498-f522d56a9669" />







# GreyMecha/Army AOC App Installation Process
1. Copy `aoc25` into `/apps/aoc25/`
2. Modify your `/apps/__init__.py` to add the app aoc entry


```python
...
import apps.aoc25.main 
...

def menu(hw_state):
    #splashscreen()
    #time.sleep(0.5)
    
    print("menu")
    curr = 0
    options = [
        "Hi I'm Locked In", "Live Firing", "Animation", "Face", "Music",
        "Brick Game", "Brick Good", "Asteroids", "Spam Game", "Controller",
        "Advent of Code 25" ### New Entry ############################
    ]
    
    ...

    while True:
        ...
        # Select Code
        if hw_state["btn_action"][0].value == False:
            ...
            ### New Entry Here ######################################################
            if options[curr] == "Advent of Code 25":
                apps.aoc25.main.app(hw_state)
                fpga_buttons = hw_state["fpga_overlay"].set_mode_buttons()
            ### New Entry Here ######################################################
            ...
```
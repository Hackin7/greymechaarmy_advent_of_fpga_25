count = 0
position = 50
with open("input.txt") as f:
    for line in f:
        str_direction = line[0]
        str_number = line[1:].strip()
        sign = 1 if str_direction == "R" else -1
        value = int(str_number) * sign
        
        position = (position + value) % 100
        if position == 0: count += 1

print(count)
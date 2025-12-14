count = 0
position = 50
with open("input.txt") as f:
    for line in f:
        str_direction = line[0]
        str_number = line[1:].strip()
        sign = 1 if str_direction == "R" else -1
        value = int(str_number) * sign

        position_long = (position + value) # Position +ve, value can be -ve
        if sign > 0:
            no_loops = position_long // 100
        elif sign < 0:
            no_loops = abs(position_long) // 100
            if position != 0:
                no_loops += (position_long <= 0)
        count += no_loops
        position = position_long % 100

        print(line.strip(), position_long, position, "->", no_loops, count)

print(count)
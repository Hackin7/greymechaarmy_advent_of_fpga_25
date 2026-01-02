data = ""

# with open("input_sample.txt") as f:
with open("input.txt") as f:
    data = f.read()

ranges = data.split(",")
ranges = [r.split('-') for r in ranges]

#print(ranges)

def min_num(l):
    return ('1' + ('0'*(l-1)))
def max_num(l):
    return ('9'*l)

def check(a, x, b):
    return a <= x <= b
def get_num(l, i):
    return i * (10**(l//2)) + i


ans = 0
def iterate_nums(a, b):
    global ans
    l = len(a)
    if len(a) % 2 == 1:
        return

    # split into half 
    a1, a2 = a[:l//2] , a[l//2:]
    b1, b2 = b[:l//2] , b[l//2:]
    #print(">", a1, a2, b1, b2)

    diff_a = int(a2) - int(a1) # Number of times the pattern can repeat
    diff_b = int(b1) - int(b2) # if it actually repeats
    
    number = get_num(l, int(a1))
    if int(a) <= number <= int(b):
        print("n1:", number)
        ans += number

    # Brute force on the half
    for i in range(int(a1)+1, int(b1)):
        number = get_num(l, i)
        print("n:", number)
        ans += number
    
    number = get_num(l, int(b1))
    if b1 != a1 and number <= int(b):
        print("n2:", number)
        ans += number

for a, b in ranges:
    #print(a,b, len(a), len(b))
    
    if len(a) == len(b):
        iterate_nums(a, b)
    else:
        iterate_nums(a, max_num(len(a)))
        for l in range(len(a)+1, len(b)):
            iterate_nums(min_num(l), max_num(l))
        iterate_nums(min_num(len(b)), b)


        

        

print(ans)
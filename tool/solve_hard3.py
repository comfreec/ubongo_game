# -*- coding: utf-8 -*-
# 어려움 퍼즐 추가 후보 - 다양한 보드 모양

PIECES = {
    'I2': [(0,0),(1,0)],
    'I3': [(0,0),(1,0),(2,0)],
    'L3': [(0,0),(1,0),(1,1)],
    'I4': [(0,0),(1,0),(2,0),(3,0)],
    'O4': [(0,0),(0,1),(1,0),(1,1)],
    'T4': [(0,0),(0,1),(0,2),(1,1)],
    'L4': [(0,0),(1,0),(2,0),(2,1)],
    'S4': [(0,1),(0,2),(1,0),(1,1)],
    'Z4': [(0,0),(0,1),(1,1),(1,2)],
    'L5': [(0,0),(1,0),(2,0),(3,0),(3,1)],
    'T5': [(0,0),(0,1),(0,2),(1,1),(2,1)],
    'P5': [(0,0),(0,1),(1,0),(1,1),(2,0)],
}

def normalize(cells):
    min_r = min(r for r,c in cells)
    min_c = min(c for r,c in cells)
    return tuple(sorted((r-min_r, c-min_c) for r,c in cells))

def rotate(cells):
    return normalize([(-c, r) for r,c in cells])

def flip(cells):
    return normalize([(-r, c) for r,c in cells])

def all_variants(cells):
    seen = set()
    result = []
    cur = normalize(cells)
    for _ in range(2):
        for _ in range(4):
            if cur not in seen:
                seen.add(cur)
                result.append(cur)
            cur = rotate(cur)
        cur = flip(cur)
    return result

def can_place(board, rows, cols, cells, pr, pc):
    for (r,c) in cells:
        nr, nc = pr+r, pc+c
        if nr<0 or nr>=rows or nc<0 or nc>=cols: return False
        if board[nr][nc] != 0: return False
    return True

def place(board, cells, pr, pc, val):
    for (r,c) in cells:
        board[pr+r][pc+c] = val

def unplace(board, cells, pr, pc):
    for (r,c) in cells:
        board[pr+r][pc+c] = 0

def first_empty(board, rows, cols):
    for r in range(rows):
        for c in range(cols):
            if board[r][c] == 0:
                return r, c
    return None, None

def solve(board, rows, cols, pieces, depth=1):
    if not pieces:
        r, c = first_empty(board, rows, cols)
        return r is None
    r, c = first_empty(board, rows, cols)
    if r is None: return False
    for i, (pid, variants) in enumerate(pieces):
        for v in variants:
            for (ar, ac) in v:
                pr, pc = r-ar, c-ac
                if can_place(board, rows, cols, v, pr, pc):
                    place(board, v, pr, pc, depth)
                    rest = pieces[:i] + pieces[i+1:]
                    if solve(board, rows, cols, rest, depth+1):
                        return True
                    unplace(board, v, pr, pc)
    return False

def check(pid, pattern, piece_ids):
    rows = len(pattern)
    cols = max(len(r) for r in pattern)
    board = []
    total = 0
    for r in range(rows):
        row = []
        for c in range(cols):
            if c < len(pattern[r]) and pattern[r][c] == '#':
                row.append(0)
                total += 1
            else:
                row.append(-1)
        board.append(row)
    
    piece_total = sum(len(PIECES[p]) for p in piece_ids)
    if total != piece_total:
        print(f'{pid}: MISMATCH board={total} pieces={piece_total}')
        return False
    
    pieces = [(p, all_variants(PIECES[p])) for p in piece_ids]
    ok = solve(board, rows, cols, pieces)
    print(f'{pid} [{",".join(piece_ids)}]: {"OK" if ok else "NO"}')
    return ok

# 불규칙 20칸 보드 (5조각)
# 5행 불규칙 (각 행 4칸, 총 20칸)
check('i01', ['####','####','####','####','####'], ['P5','T4','L4','S4','I3'])
check('i02', ['####','####','####','####','####'], ['T5','T4','L4','S4','I3'])
check('i03', ['####','####','####','####','####'], ['L5','T4','L4','S4','I3'])
check('i04', ['####','####','####','####','####'], ['L5','T5','P5','I3','I2'])
check('i05', ['####','####','####','####','####'], ['T5','P5','T4','L4','I2'])
check('i06', ['####','####','####','####','####'], ['L5','P5','T4','L4','I2'])

# 불규칙 모양 (20칸)
check('i07', ['#####','######','#########'], ['T4','L4','S4','Z4','O4'])  # 5+6+9=20? no
check('i08', ['####.','#####','####.','####.'], ['P5','T4','L4','S4','I3'])  # 4+5+4+4=17 no
check('i09', ['.####','#####','.####','#####'], ['P5','T4','L4','S4','I3'])  # 4+5+4+5=18 no

# 정확히 20칸 불규칙
check('i10', ['#####','######','#########'], ['T4','L4','S4','Z4','O4'])
check('i11', ['##.##','#####','##.##','#####'], ['P5','T4','L4','S4','I3'])  # 4+5+4+5=18 no

# 올바른 불규칙 20칸
check('i12', ['####.','#####','#####','####.'], ['P5','T4','L4','S4','I3'])  # 4+5+5+4=18 no
check('i13', ['.####','#####','#####','.####'], ['P5','T4','L4','S4','I3'])  # 4+5+5+4=18 no

# 4x5 불규칙 (20칸)
check('i14', ['#####','#####','#####','#####'], ['P5','T4','L4','Z4','I2'])  # 5+4+4+4+2=19 no
check('i15', ['#####','#####','#####','#####'], ['P5','T4','L4','Z4','L3'])  # 5+4+4+4+3=20
check('i16', ['#####','#####','#####','#####'], ['P5','T4','S4','Z4','L3'])
check('i17', ['#####','#####','#####','#####'], ['P5','L4','S4','Z4','L3'])
check('i18', ['#####','#####','#####','#####'], ['T5','T4','S4','Z4','L3'])
check('i19', ['#####','#####','#####','#####'], ['T5','L4','S4','Z4','L3'])
check('i20', ['#####','#####','#####','#####'], ['L5','T4','S4','Z4','L3'])
check('i21', ['#####','#####','#####','#####'], ['L5','L4','S4','Z4','L3'])
check('i22', ['#####','#####','#####','#####'], ['P5','T4','L4','O4','L3'])
check('i23', ['#####','#####','#####','#####'], ['T5','T4','L4','O4','L3'])
check('i24', ['#####','#####','#####','#####'], ['L5','T4','L4','O4','L3'])
check('i25', ['#####','#####','#####','#####'], ['P5','T4','L4','I4','L3'])
check('i26', ['#####','#####','#####','#####'], ['T5','T4','L4','I4','L3'])
check('i27', ['#####','#####','#####','#####'], ['L5','T4','L4','I4','L3'])

# 5x4 불규칙
check('i28', ['####','####','####','####','####'], ['P5','T4','L4','Z4','L3'])
check('i29', ['####','####','####','####','####'], ['P5','T4','S4','Z4','L3'])
check('i30', ['####','####','####','####','####'], ['T5','T4','S4','Z4','L3'])
check('i31', ['####','####','####','####','####'], ['L5','T4','S4','Z4','L3'])
check('i32', ['####','####','####','####','####'], ['P5','T4','L4','O4','L3'])
check('i33', ['####','####','####','####','####'], ['T5','T4','L4','O4','L3'])
check('i34', ['####','####','####','####','####'], ['L5','T4','L4','O4','L3'])

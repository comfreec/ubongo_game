# -*- coding: utf-8 -*-
# 어려움 퍼즐 후보 검증 (Python 백트래킹)
from itertools import permutations

# 조각 정의 (cells: list of (row, col))
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
    print(f'{pid} [{",".join(piece_ids)}]: {"OK ✓" if ok else "NO SOLUTION ✗"}')
    return ok

# ── 후보 퍼즐들 ──────────────────────────────────────────────

# 4x5 직사각형 (20칸), 5조각
check('h01', ['#####','#####','#####','#####'], ['T4','L4','S4','Z4','O4'])
check('h02', ['#####','#####','#####','#####'], ['T4','L4','S4','O4','I4'])
check('h03', ['#####','#####','#####','#####'], ['T4','Z4','L4','I4','O4'])
check('h04', ['#####','#####','#####','#####'], ['T4','S4','Z4','I4','O4'])

# 5x4 직사각형 (20칸)
check('h05', ['####','####','####','####','####'], ['T4','L4','S4','Z4','O4'])
check('h06', ['####','####','####','####','####'], ['T4','L4','S4','O4','I4'])
check('h07', ['####','####','####','####','####'], ['T4','Z4','L4','I4','O4'])
check('h08', ['####','####','####','####','####'], ['T4','S4','Z4','I4','O4'])

# 5조각 (5칸짜리 포함)
# P5+T4+L4+S4+I3 = 5+4+4+4+3 = 20
check('h09', ['#####','#####','#####','#####'], ['P5','T4','L4','S4','I3'])
check('h10', ['####','####','####','####','####'], ['P5','T4','L4','S4','I3'])
check('h11', ['#####','#####','#####','#####'], ['T5','T4','L4','S4','I3'])
check('h12', ['####','####','####','####','####'], ['T5','T4','L4','S4','I3'])
check('h13', ['#####','#####','#####','#####'], ['L5','T4','L4','S4','I3'])
check('h14', ['####','####','####','####','####'], ['L5','T4','L4','S4','I3'])

# L5+T5+P5+I3+I2 = 5+5+5+3+2 = 20
check('h15', ['#####','#####','#####','#####'], ['L5','T5','P5','I3','I2'])
check('h16', ['####','####','####','####','####'], ['L5','T5','P5','I3','I2'])

# T5+P5+T4+L4+I2 = 5+5+4+4+2 = 20
check('h17', ['#####','#####','#####','#####'], ['T5','P5','T4','L4','I2'])
check('h18', ['####','####','####','####','####'], ['T5','P5','T4','L4','I2'])

# L5+P5+T4+L4+I2 = 5+5+4+4+2 = 20
check('h19', ['#####','#####','#####','#####'], ['L5','P5','T4','L4','I2'])
check('h20', ['####','####','####','####','####'], ['L5','P5','T4','L4','I2'])

# 불규칙 보드
check('h21', ['.####','#####','#####','####.'], ['T4','L4','S4','Z4','O4'])
check('h22', ['####.','#####','#####','.####'], ['T4','L4','S4','Z4','O4'])
check('h23', ['.####','#####','#####','####.'], ['T5','L4','S4','Z4','I3'])
check('h24', ['####.','#####','#####','.####'], ['T5','L4','S4','Z4','I3'])
check('h25', ['.####','#####','#####','####.'], ['P5','L4','S4','Z4','I3'])
check('h26', ['####.','#####','#####','.####'], ['P5','L4','S4','Z4','I3'])

# 6조각 (더 어려움) - 총 칸 수 맞추기
# T4+L4+S4+Z4+O4+I2 = 4+4+4+4+4+2 = 22
check('h27', ['######','######','######','####..'], ['T4','L4','S4','Z4','O4','I2'])
check('h28', ['######','######','######','####..'], ['T4','L4','S4','Z4','O4','L3'])
check('h29', ['######','######','######','###...'], ['T4','L4','S4','Z4','O4','I3'])
check('h30', ['######','######','######','###...'], ['T4','L4','S4','Z4','O4','L3'])

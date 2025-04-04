sepc:
设计 SAD 计算逻辑,对输入的2个16x16 矩阵(din 和 refi)做如下运算：
SAD = ∑∑abs(din[y][x] − refi[y][x]).
1) din[y][x]/refi[y][x]是 8bit的无符号数;
2) abs()是求绝对值运算;
3) SAD 是两个输入矩阵对应点的差的绝对值的求和;
model: 5_level pipeline design

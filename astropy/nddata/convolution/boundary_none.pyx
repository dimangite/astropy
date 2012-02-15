from __future__ import division
import numpy as np
cimport numpy as np

DTYPE = np.float
ctypedef np.float_t DTYPE_t

cdef extern from "math.h":
    bint isnan(double x)

cimport cython


@cython.boundscheck(False)  # turn of bounds-checking for entire function
def convolve2d_boundary_none(np.ndarray[DTYPE_t, ndim=2] f,
                             np.ndarray[DTYPE_t, ndim=2] g):

    if g.shape[0] % 2 != 1 or g.shape[1] % 2 != 1:
        raise ValueError("Convolution kernel must have odd dimensions")

    assert f.dtype == DTYPE and g.dtype == DTYPE

    cdef int nx = f.shape[0]
    cdef int ny = f.shape[1]
    cdef int nkx = g.shape[0]
    cdef int nky = g.shape[1]
    cdef int wkx = nkx // 2
    cdef int wky = nky // 2

    # The following need to be set to zeros rather than empty because the
    # boundary does not get reset.
    cdef np.ndarray[DTYPE_t, ndim=2] fixed = np.zeros([nx, ny], dtype=DTYPE)
    cdef np.ndarray[DTYPE_t, ndim=2] conv = np.zeros([nx, ny], dtype=DTYPE)

    cdef unsigned int i, j, ii, jj

    cdef int iimin, iimax, jjmin, jjmax

    cdef DTYPE_t top, bot, ker, val

    # Need a first pass to replace NaN values with value convolved from
    # neighboring values
    for i in range(wkx, nx - wkx):
        for j in range(wky, ny - wky):
            if isnan(f[i, j]):
                top = 0.
                bot = 0.
                for ii in range(i - wkx, i + wkx + 1):
                    for jj in range(j - wky, j + wky + 1):
                        val = f[ii, jj]
                        if not isnan(val):
                            ker = g[<unsigned int>(wkx + ii - i),
                                    <unsigned int>(wky + jj - j)]
                            top += val * ker
                            bot += ker
                if bot != 0.:
                    fixed[i, j] = top / bot
                else:
                    fixed[i, j] = f[i, j]
            else:
                fixed[i, j] = f[i, j]

    # Now run the proper convolution
    for i in range(wkx, nx - wkx):
        for j in range(wky, ny - wky):
            if not isnan(fixed[i, j]):
                top = 0.
                bot = 0.
                for ii in range(i - wkx, i + wkx + 1):
                    for jj in range(j - wky, j + wky + 1):
                        val = fixed[ii, jj]
                        ker = g[<unsigned int>(wkx + ii - i),
                                <unsigned int>(wky + jj - j)]
                        if not isnan(val):
                            top += val * ker
                            bot += ker
                if bot != 0:
                    conv[i, j] = top / bot
                else:
                    conv[i, j] = fixed[i, j]
            else:
                conv[i, j] = fixed[i, j]

    return conv

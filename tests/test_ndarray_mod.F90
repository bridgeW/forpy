! Copyright (C) 2017-2018  Elias Rabel
!
! This program is free software: you can redistribute it and/or modify
! it under the terms of the GNU Lesser General Public License as published by 
! the Free Software Foundation, either version 3 of the License, or 
! (at your option) any later version.
!
! This program is distributed in the hope that it will be useful,
! but WITHOUT ANY WARRANTY; without even the implied warranty of 
! MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
! GNU Lesser General Public License for more details.
!
! You should have received a copy of the GNU Lesser General Public License
! along with this program.  If not, see <http://www.gnu.org/licenses/>.

module test_ndarray_mod
use unittest_mod
use forpy_mod
use iso_fortran_env
use iso_c_binding
implicit none

type(module_py), save :: test_mod

CONTAINS

#include "unittest_mod.inc"

subroutine test_ndarray_expected()
  integer ierror
  type(tuple) :: args
  type(ndarray) :: nd_arr
  integer arr(1)
  arr(1) = 42
  ierror = tuple_create(args, 1)
  ierror = ndarray_create(nd_arr, arr)
  ierror = args%setitem(0, nd_arr)
  ierror = call_py_noret(test_mod, "ndarray_expected", args)
  ASSERT(ierror==0)
  ASSERT(.not. have_exception())
  call args%destroy
  call nd_arr%destroy
end subroutine

subroutine test_check_ndarray_1d()
  integer ierror
  type(tuple) :: args
  type(ndarray) :: nd_arr
  integer arr(24)
  integer ii
  
  do ii = 1,24
    arr(ii) = ii
  enddo
  ierror = tuple_create(args, 1)
  ierror = ndarray_create(nd_arr, arr)
  ierror = args%setitem(0, nd_arr)
  ierror = call_py_noret(test_mod, "check_ndarray_1d", args)
  ASSERT(ierror==0)
  ASSERT(.not. have_exception())
  call args%destroy
  call nd_arr%destroy
end subroutine

subroutine test_check_ndarray_2d()
  integer ierror
  type(tuple) :: args
  type(ndarray) :: nd_arr
  real(kind=real64) :: arr(4,6)
  integer ii, jj
  
  do ii = 1,4
    do jj = 1,6
      arr(ii, jj) = real((ii-1)*6 + jj, kind=real64)
    enddo
  enddo
  
  ierror = tuple_create(args, 1)
  ierror = ndarray_create(nd_arr, arr)
  ierror = args%setitem(0, nd_arr)
  ierror = call_py_noret(test_mod, "check_ndarray_2d", args)
  ASSERT(ierror==0)
  ASSERT(.not. have_exception())
  call args%destroy
  call nd_arr%destroy
end subroutine

subroutine test_check_ndarray_3d()
  integer ierror
  type(tuple) :: args
  type(ndarray) :: nd_arr
  real(kind=real32) :: arr(2,3,4)
  integer ii, jj,kk
  
  do ii = 1,2
    do jj = 1,3
      do kk = 1,4
        arr(ii, jj, kk) = real((ii-1)*12 + (jj-1)*4 + kk, kind=real32)
      enddo
    enddo
  enddo
  
  ierror = tuple_create(args, 1)
  ierror = ndarray_create(nd_arr, arr)
  ierror = args%setitem(0, nd_arr)
  ierror = call_py_noret(test_mod, "check_ndarray_3d", args)
  ASSERT(ierror==0)
  ASSERT(.not. have_exception())
  call args%destroy
  call nd_arr%destroy
end subroutine

subroutine test_get_ndarray_2d()
  integer ierror
  type(object) :: retval
  type(ndarray) :: nd_arr
  real(kind=real64) :: solution
  real(kind=real64), dimension(:,:), pointer :: arr
  integer ii, jj
    
  ierror = call_py(retval, test_mod, "get_ndarray_2d")
  ASSERT(ierror==0)
  ASSERT(.not. have_exception())
  
  ierror = cast(nd_arr, retval)
  call retval%destroy
  ASSERT(ierror==0)
  
  ierror = nd_arr%get_data(arr)
  ASSERT(ierror==0)
  
  ASSERT(size(arr,1)==4)
  ASSERT(size(arr,2)==6)
  
  do jj = 1,6
    do ii = 1,4
      solution = real((jj-1)*4 + ii, kind=real64)
      ASSERT(arr(ii,jj)==solution)
    enddo
  enddo
  
  call nd_arr%destroy
  
end subroutine

subroutine test_get_ndarray_wrong_order()
  !expecting Fortran order, but getting a C-ordered array
  integer ierror
  type(object) :: retval
  type(ndarray) :: nd_arr
  real(kind=real64), dimension(:,:), pointer :: arr
  logical exc_correct
    
  ierror = call_py(retval, test_mod, "get_ndarray_2d_c_order")
  ASSERT(ierror==0)
  ASSERT(.not. have_exception())
  
  ierror = cast(nd_arr, retval)
  call retval%destroy
  ASSERT(ierror==0)
  
  ierror = nd_arr%get_data(arr)
  ASSERT(ierror==EXCEPTION_ERROR)
  exc_correct=exception_matches(BufferError)
  ASSERT(exc_correct)
  call err_clear

  call nd_arr%destroy
  
end subroutine

subroutine test_get_ndarray_bad_dim()
  !expecting 1d-array, but getting 2d-array
  integer ierror
  type(object) :: retval
  type(ndarray) :: nd_arr
  real(kind=real64), dimension(:), pointer :: arr
    
  ierror = call_py(retval, test_mod, "get_ndarray_2d")
  ASSERT(ierror==0)
  ASSERT(.not. have_exception())

  ierror = cast(nd_arr, retval)
  call retval%destroy
  ASSERT(ierror==0)
  
  ierror = nd_arr%get_data(arr)
  ASSERT(ierror==EXCEPTION_ERROR)
  ASSERT(exception_matches(TypeError))
  call err_clear

  call nd_arr%destroy
  
end subroutine

subroutine test_get_ndarray_bad_type()
  !expecting int32-array, getting real64
  integer ierror
  type(object) :: retval
  type(ndarray) :: nd_arr
  integer(kind=int32), dimension(:,:), pointer :: arr
    
  ierror = call_py(retval, test_mod, "get_ndarray_2d")
  ASSERT(ierror==0)
  ASSERT(.not. have_exception())
  
  ierror = cast(nd_arr, retval)
  call retval%destroy
  ASSERT(ierror==0)
  
  ierror = nd_arr%get_data(arr)
  ASSERT(ierror==EXCEPTION_ERROR)
  ASSERT(exception_matches(TypeError))
  call err_clear

  call nd_arr%destroy
  
end subroutine

subroutine test_get_ndarray_discont()
  !expecting Fortran order, but getting a discontiguous-array
  integer ierror
  type(object) :: retval
  type(ndarray) :: nd_arr
  real(kind=real64), dimension(:,:), pointer :: arr
  logical exc_correct
    
  ierror = call_py(retval, test_mod, "get_ndarray_2d_not_contiguous")
  ASSERT(ierror==0)
  ASSERT(.not. have_exception())
  
  ierror = cast(nd_arr, retval)
  call retval%destroy
  ASSERT(ierror==0)
  
  ierror = nd_arr%get_data(arr)
  ASSERT(ierror==EXCEPTION_ERROR)
  exc_correct = exception_matches(BufferError)
  ASSERT(exc_correct)
  call err_clear

  call nd_arr%destroy
  
end subroutine

subroutine test_get_ndarray_c_order()
  !get C-ordered array
  integer ierror
  type(object) :: retval
  type(ndarray) :: nd_arr
  real(kind=real64), dimension(:,:), pointer :: arr
  real(kind=real64) solution
  integer ii, jj
    
  ierror = call_py(retval, test_mod, "get_ndarray_2d_c_order")
  ASSERT(ierror==0)
  ASSERT(.not. have_exception())
  
  ierror = cast(nd_arr, retval)
  call retval%destroy
  ASSERT(ierror==0)
  
  ierror = nd_arr%get_data(arr, 'A')
  ASSERT(ierror==0)
  ASSERT(.not. have_exception())

  do ii = 1,6
    do jj = 1,4
      solution = real((jj-1)*6 + ii, kind=real64)
      ASSERT(arr(ii,jj)==solution)
    enddo
  enddo

  call nd_arr%destroy
  
end subroutine

subroutine test_bad_order_param()
  !passing a bad order parameter
  integer ierror
  type(ndarray) :: nd_arr
  integer, dimension(:), pointer :: arr
  integer :: testarr(2) = [1, 2]
  logical :: exc_correct
  
  ierror = ndarray_create(nd_arr, testarr)
  ASSERT(ierror==0)  
  ierror = nd_arr%get_data(arr, order='Q') !'Q' is not a valid value for order
  ASSERT(ierror==EXCEPTION_ERROR)
  exc_correct = exception_matches(ValueError)
  ASSERT(exc_correct)
  call err_clear
    
  call nd_arr%destroy
end subroutine

subroutine test_order_1d_array()
  !for 1D array, the distinction between Fortran- and C-order does not matter
  integer ierror
  type(ndarray) :: nd_arr
  integer, dimension(:), pointer :: arr
  integer :: testarr(2) = [1, 2]
  
  ierror = ndarray_create(nd_arr, testarr)
  ASSERT(ierror==0)
  ! all order parameters must work
  ierror = nd_arr%get_data(arr, order='F')
  ASSERT(ierror==0)
  ierror = nd_arr%get_data(arr, order='C')
  ASSERT(ierror==0)
  ierror = nd_arr%get_data(arr, order='A')
  ASSERT(ierror==0)
    
  call nd_arr%destroy
end subroutine

subroutine test_check_transpose2d()
  integer ierror
  type(object) :: retval
  type(ndarray) :: nd_arr, nd_arr_trans
  type(tuple) :: args
    
  ierror = call_py(retval, test_mod, "get_ndarray_2d")
  ASSERT(ierror==0)
  ASSERT(.not. have_exception())
  
  ierror = cast(nd_arr, retval)
  call retval%destroy
  ASSERT(ierror==0)
  
  ierror = nd_arr%transpose(nd_arr_trans)
  ASSERT(ierror==0)
  
  ierror = tuple_create(args, 1)
  ierror = args%setitem(0, nd_arr_trans)
  ierror = call_py_noret(test_mod, "check_transpose_2d", args)
  ASSERT(ierror==0)
  ASSERT(.not. have_exception())
  
  call args%destroy
  call nd_arr%destroy
  call nd_arr_trans%destroy
end subroutine

subroutine test_copy()
  integer ierror
  type(ndarray) :: nd_arr, nd_arr_copy
  integer, dimension(:), pointer :: arr, arr_copy
  integer :: testarr(2) = [314, 297]
  
  ierror = ndarray_create(nd_arr, testarr)
  ASSERT(ierror==0)  
  ierror = nd_arr%copy(nd_arr_copy)
  ASSERT(ierror==0)
  ierror = nd_arr%get_data(arr)
  ASSERT(ierror==0)
  ierror = nd_arr_copy%get_data(arr_copy)
  ASSERT(ierror==0)
  
  ASSERT(all(arr==arr_copy))
  arr(1) = 12345
  ASSERT(.not. all(arr==arr_copy))
    
  call nd_arr%destroy
  call nd_arr_copy%destroy
end subroutine

subroutine test_copy_order()
  !creating C-ordered array from Fortran-ordered array by copying
  integer ierror
  type(object) :: retval
  type(ndarray) :: nd_arr, nd_arr_copy
  type(tuple) :: args
    
  ierror = call_py(retval, test_mod, "get_ndarray_2d") !returned array has Fortran-order
  ASSERT(ierror==0)
  
  ierror = cast(nd_arr, retval)
  call retval%destroy
  ASSERT(ierror==0)
  
  ierror = nd_arr%copy(nd_arr_copy, 'C')
  ASSERT(ierror==0)
  
  ierror = tuple_create(args, 1)
  ierror = args%setitem(0, nd_arr_copy)
  ierror = call_py_noret(test_mod, "c_order_expected", args)
  ASSERT(ierror==0)
  ASSERT(.not. have_exception())

  call args%destroy
  call nd_arr%destroy
  call nd_arr_copy%destroy
end subroutine

subroutine test_is_ordered_fortran()
  integer ierror
  type(object) :: retval
  type(ndarray) :: nd_arr
    
  ierror = call_py(retval, test_mod, "get_ndarray_2d") !returned array has Fortran-order
  ASSERT(ierror==0)
  
  ierror = cast(nd_arr, retval)
  call retval%destroy
  ASSERT(ierror==0)
  
  ASSERT(nd_arr%is_ordered('F'))
  ASSERT(.not. nd_arr%is_ordered('C'))
  ASSERT(nd_arr%is_ordered('A'))

  call nd_arr%destroy
end subroutine

subroutine test_is_ordered_c()
  integer ierror
  type(object) :: retval
  type(ndarray) :: nd_arr
    
  ierror = call_py(retval, test_mod, "get_ndarray_2d_c_order") !returned array has C-order
  ASSERT(ierror==0)
  
  ierror = cast(nd_arr, retval)
  call retval%destroy
  ASSERT(ierror==0)
  
  ASSERT(.not. nd_arr%is_ordered('F'))
  ASSERT(nd_arr%is_ordered('C'))
  ASSERT(nd_arr%is_ordered('A'))

  call nd_arr%destroy
end subroutine

subroutine test_is_ordered_discont()
  integer ierror
  type(object) :: retval
  type(ndarray) :: nd_arr
    
  ierror = call_py(retval, test_mod, "get_ndarray_2d_not_contiguous")
  ASSERT(ierror==0)
  
  ierror = cast(nd_arr, retval)
  call retval%destroy
  ASSERT(ierror==0)
  
  ASSERT(.not. nd_arr%is_ordered('F'))
  ASSERT(.not. nd_arr%is_ordered('C'))
  ASSERT(.not. nd_arr%is_ordered('A'))

  call nd_arr%destroy
end subroutine

subroutine test_is_ordered_1d()
  !for 1D array, the distinction between Fortran- and C-order does not matter
  integer ierror
  type(ndarray) :: nd_arr
  integer :: testarr(2) = [1, 2]
  
  ierror = ndarray_create(nd_arr, testarr)
  ASSERT(ierror==0)
  ASSERT(nd_arr%is_ordered('F'))
  ASSERT(nd_arr%is_ordered('C'))
  ASSERT(nd_arr%is_ordered('A'))
  ! test bad order parameter
  ASSERT(.not. nd_arr%is_ordered('Q'))
    
  call nd_arr%destroy
end subroutine

subroutine test_get_dtype_name()
  integer ierror
  type(ndarray) :: nd_arr
  real(kind=real64) :: testarr(1) = [42.0_real64]
  character(kind=C_CHAR, len=:), allocatable :: dname
  
  ierror = ndarray_create(nd_arr, testarr)
  ASSERT(ierror==0)
  ierror = nd_arr%get_dtype_name(dname)
  ASSERT(ierror==0)
  ASSERT(dname=='float64')
    
  call nd_arr%destroy
end subroutine

subroutine test_ndim()
  integer ierror
  type(ndarray) :: nd_arr
  integer :: testarr(2,3,4)
  integer :: ndim
  
  testarr = 0
  ierror = ndarray_create(nd_arr, testarr)
  ASSERT(ierror==0)
  ierror = nd_arr%ndim(ndim)
  ASSERT(ndim==3)
    
  call nd_arr%destroy
end subroutine

subroutine test_ndarray_create_empty01()
  integer ierror
  type(ndarray) :: nd_arr
  integer :: nx, ny
  real(kind=real64), dimension(:,:), pointer :: ptr
  nx = 3
  ny = 4
  ierror = ndarray_create_empty(nd_arr, [nx,ny], dtype="float64")
  ASSERT(ierror==0)
  ierror = nd_arr%get_data(ptr)
  ASSERT(ierror==0)
  ASSERT(size(ptr,1)==nx)
  ASSERT(size(ptr,2)==ny)
  call nd_arr%destroy
end subroutine

subroutine test_ndarray_create_empty02()
  integer ierror
  type(ndarray) :: nd_arr
  integer :: nx, ny
  real(kind=real64), dimension(:,:), pointer :: ptr
  nx = 3
  ny = 4
  ierror = ndarray_create_empty(nd_arr, [nx,ny], order="C")
  ASSERT(ierror==0)
  ierror = nd_arr%get_data(ptr, order="C")
  ASSERT(ierror==0)
  ASSERT(size(ptr,1)==ny)
  ASSERT(size(ptr,2)==nx)
  call nd_arr%destroy
end subroutine

subroutine test_ndarray_create_empty03()
  integer ierror
  type(ndarray) :: nd_arr
  integer(kind=int64) :: nx
  integer(kind=int64), dimension(:), pointer :: ptr
  nx = 11
  ierror = ndarray_create_empty(nd_arr, nx, dtype="int64", order="C")
  ASSERT(ierror==0)
  ierror = nd_arr%get_data(ptr, order="C")
  ASSERT(ierror==0)
  ASSERT(size(ptr,1)==nx)
  call nd_arr%destroy
end subroutine

subroutine test_ndarray_create_zeros01()
  integer ierror
  type(ndarray) :: nd_arr
  integer :: nx, ny
  real(kind=real64), dimension(:,:), pointer :: ptr
  nx = 2
  ny = 6
  ierror = ndarray_create_zeros(nd_arr, [nx,ny], dtype="float64")
  ASSERT(ierror==0)
  ierror = nd_arr%get_data(ptr)
  ASSERT(ierror==0)
  ASSERT(size(ptr,1)==nx)
  ASSERT(size(ptr,2)==ny)
  ASSERT(all(ptr==0.0_real64))
  call nd_arr%destroy
end subroutine

subroutine test_ndarray_create_zeros02()
  integer ierror
  type(ndarray) :: nd_arr
  integer :: nx, ny
  real(kind=real64), dimension(:,:), pointer :: ptr
  nx = 3
  ny = 4
  ierror = ndarray_create_zeros(nd_arr, [nx,ny], order="C")
  ASSERT(ierror==0)
  ierror = nd_arr%get_data(ptr, order="C")
  ASSERT(ierror==0)
  ASSERT(size(ptr,1)==ny)
  ASSERT(size(ptr,2)==nx)
  ASSERT(all(ptr==0.0_real64))
  call nd_arr%destroy
end subroutine

subroutine test_ndarray_create_zeros03()
  integer ierror
  type(ndarray) :: nd_arr
  integer(kind=int64) :: nx
  integer(kind=int64), dimension(:), pointer :: ptr
  nx = 11
  ierror = ndarray_create_zeros(nd_arr, nx, dtype="int64")
  ASSERT(ierror==0)
  ierror = nd_arr%get_data(ptr, order="C")
  ASSERT(ierror==0)
  ASSERT(size(ptr,1)==nx)
  ASSERT(all(ptr==0_int64))
  call nd_arr%destroy
end subroutine

subroutine test_ndarray_create_ones01()
  integer ierror
  type(ndarray) :: nd_arr
  integer :: nx, ny
  complex(kind=real64), dimension(:,:), pointer :: ptr
  complex(kind=real64), parameter :: C_ONE = (1.0_real64, 0.0_real64)
  nx = 2
  ny = 6
  ierror = ndarray_create_ones(nd_arr, [nx,ny], dtype="complex128")
  ASSERT(ierror==0)
  ierror = nd_arr%get_data(ptr)
  ASSERT(ierror==0)
  ASSERT(size(ptr,1)==nx)
  ASSERT(size(ptr,2)==ny)
  ASSERT(all(ptr==C_ONE))
  call nd_arr%destroy
end subroutine

subroutine test_ndarray_create_ones02()
  integer ierror
  type(ndarray) :: nd_arr
  integer :: nx, ny
  real(kind=real64), dimension(:,:), pointer :: ptr
  nx = 3
  ny = 4
  ierror = ndarray_create_ones(nd_arr, [nx,ny], order="C")
  ASSERT(ierror==0)
  ierror = nd_arr%get_data(ptr, order="C")
  ASSERT(ierror==0)
  ASSERT(size(ptr,1)==ny)
  ASSERT(size(ptr,2)==nx)
  ASSERT(all(ptr==1.0_real64))
  call nd_arr%destroy
end subroutine

subroutine test_ndarray_create_ones03()
  integer ierror
  type(ndarray) :: nd_arr
  integer(kind=int64) :: nx
  integer(kind=int64), dimension(:), pointer :: ptr
  nx = 11
  ierror = ndarray_create_ones(nd_arr, nx, dtype="int64")
  ASSERT(ierror==0)
  ierror = nd_arr%get_data(ptr, order="C")
  ASSERT(ierror==0)
  ASSERT(size(ptr,1)==nx)
  ASSERT(all(ptr==1_int64))
  call nd_arr%destroy
end subroutine

! code to execute before every test
subroutine setUp()

end subroutine

subroutine tearDown()
  !check if there is an uncleared exception - if yes, fail the test and clear
  if (have_exception()) then
    call fail_test
    write(*,*) "The test did not clear the following exception:"
    call err_print
  endif
end subroutine

subroutine setUpClass()
  integer ierror
  type(list) :: paths
  
  ierror = forpy_initialize()
  
  if (ierror /= 0) then
    write (*,*) "Initialisation of forpy failed!!! Can not test. Errorcode = ", ierror
    stop
  endif
  
  ! add current dir (".") to search path
  ierror = get_sys_path(paths)
  if (ierror == 0) then
    ierror = paths%append(".")
    call paths%destroy
  endif
  
  if (ierror /= 0) then
    write(*,*) "Error setting PYTHONPATH. Cannot test...", ierror
    call err_print
    STOP
  endif

  ierror = import_py(test_mod, "test_ndarray")
  if (ierror /= 0) then
    write(*,*) "Could not import test module 'test_ndarray'. Cannot test..."
    STOP
  endif
end subroutine

subroutine tearDownClass()
  call test_mod%destroy
  call forpy_finalize()
  call print_test_count
end subroutine

end module

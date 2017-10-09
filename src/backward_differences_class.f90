#include "scalar.fpp"

!=====================================================================!
! Backward Difference Formulas integration module for differential 
! equations.
!
! Author: Komahan Boopathy (komahan@gatech.edu)
!=====================================================================! 

module backward_differences_integrator_class

  use integrator_interface      , only : integrator
  use dynamic_physics_interface , only : dynamics
  use utils, only : real_part

  implicit none

  private
  public :: BDF
  
  !===================================================================! 
  ! BDF Integrator type
  !===================================================================! 

  type, extends(integrator) :: BDF
     
     private

     ! BDF variables
     type(integer)             :: max_bdf_order = 6
     type(scalar), allocatable :: A(:,:)

   contains
           
     procedure :: step
     procedure :: get_linearization_coeff
     procedure :: get_accuracy_order

     ! Destructor
     final :: destroy

  end type BDF

  interface BDF
     module procedure create
  end interface BDF

contains

  !===================================================================!
  ! Initialize the BDF datatype and allocate required variables
  !===================================================================!
  
  type(bdf) function create(system, tinit, tfinal, h, implicit, &
       & accuracy_order) result(this)

    class(dynamics)   , intent(in)   , target :: system
    type(scalar)      , intent(in)            :: tinit, tfinal
    type(scalar)      , intent(in)            :: h
    type(integer)     , intent(in)            :: accuracy_order
    type(logical)     , intent(in)            :: implicit   

    print *, "======================================"
    print *, ">>   Backward Difference Formulas  << "
    print *, "======================================"

    call this % construct(system, tinit, tfinal, h, implicit, num_stages=0)

    !-----------------------------------------------------------------!
    ! Set the order of integration
    !-----------------------------------------------------------------!

    if (accuracy_order .le. this % max_bdf_order) this % max_bdf_order = accuracy_order
    print '("  >> Max BDF Order          : ",i4)', this % max_bdf_order

    allocate( this % A (this % max_bdf_order, this % max_bdf_order+1) )
    this % A = 0.0d0 

    ! Set the coefficients
    ! http://www.scholarpedia.org/article/Backward_differentiation_formulas
    if ( this % max_bdf_order .ge. 1 ) this % A(1,1:2) = [1.0d0, -1.0d0]
    if ( this % max_bdf_order .ge. 2 ) this % A(2,1:3) = [3.0d0, -4.0d0, 1.0d0]/2.0d0
    if ( this % max_bdf_order .ge. 3 ) this % A(3,1:4) = [11.0d0, -18.0d0, 9.0d0, -2.0d0]/6.0d0
    if ( this % max_bdf_order .ge. 4 ) this % A(4,1:5) = [25.0d0, -48.0d0, 36.0d0, -16.0d0, 3.0d0]/12.0d0
    if ( this % max_bdf_order .ge. 5 ) this % A(5,1:6) = [137.0d0, -300.0d0, 300.0d0, -200.0d0, 75.0d0, -12.0d0]/60.0d0
    if ( this % max_bdf_order .ge. 6 ) this % A(6,1:7) = [147.0d0, -360.0d0, 450.0d0, -400.0d0, 225.0d0, -72.0d0, 10.0d0]/60.0d0

    ! Sanity check on BDF coeffs
    sanity_check: block
      type(integer) :: j
      do j = 1, this % max_bdf_order
         if (abs(sum(real_part(this % A(j,1:j+1)))) .gt. 1.0d-15 ) then
            print *, "Error in BDF Coeff for order ", abs(sum(real_part(this % A(j,1:j+1)))), j
            stop
         end if
      end do
    end block sanity_check
    
  end function create

  !=================================================================!
  ! Destructor for the BDF integrator
  !=================================================================!
  
  impure subroutine destroy(this)

    type(BDF), intent(inout) :: this

    ! Parent class call
    call this % destruct()

    ! Deallocate BDF coefficient
    if(allocated(this % A)) deallocate(this % A)

  end subroutine destroy

  !===================================================================!
  ! Returns the order of approximation for the given time step k and
  ! degree d
  !===================================================================!

  pure type(integer) function get_accuracy_order(this, time_index) result(order)

    class(BDF)   , intent(in) :: this
    type(integer), intent(in) :: time_index

    order = time_index - 1

    if (order .gt. this % max_bdf_order) order = this % max_bdf_order

  end function get_accuracy_order

  !================================================================!
  ! Take a time step using the supplied time step and order of
  ! accuracy
  ! ================================================================!

  impure subroutine step(this, t, u, h, p, ierr)

    use nonlinear_algebra, only : solve

    ! Argument variables
    class(BDF)   , intent(inout) :: this
    type(scalar) , intent(inout) :: t(:)
    type(scalar) , intent(inout) :: u(:,:,:)
    type(integer), intent(in)    :: p
    type(scalar) , intent(in)    :: h
    type(integer), intent(out)   :: ierr

    ! Local variables
    type(scalar), allocatable :: lincoeff(:)  ! order of equation + 1
    type(integer) :: torder, n, i, k
    type(scalar)  :: scale
    
    ! Determine remaining paramters needed
    k = size(u(:,1,1))
    torder = this % system % get_differential_order()

    ! Advance the time to next step
    t(k) = t(k-1) + h

    ! Assume a value for lowest order state
    u(k,1,:) = 0.0d0

    ! Find the higher order states based on BDF formula
    do n = 1, torder
       do i = 0, p
          scale = this % A(p,i+1)/h !(t(k-i)-t(k-i-1))
          u(k,n+1,:) = u(k,n+1,:) + scale*u(k-i,n,:)
       end do
    end do

    ! Perform a nonlinear solution if this is a implicit method
    if ( this % is_implicit() ) then
       allocate(lincoeff(torder+1))         
       call this % get_linearization_coeff(lincoeff, p, h)         
       call solve(this % system, lincoeff, t(k), u(k,:,:))
       deallocate(lincoeff)        
    end if

  end subroutine step

  !================================================================!
  ! Retrieve the coefficients for linearizing the jacobian
  !================================================================!
  
  impure subroutine get_linearization_coeff(this, lincoeff, int_order, h)
    
    class(BDF)    , intent(in)  :: this
    type(integer) , intent(in)  :: int_order     ! order of approximation of the integration
    type(scalar)  , intent(in)  :: h 
    type(scalar)  , intent(inout) :: lincoeff(:) ! diff_order+1

    compute_coeffs: block

      type(integer) :: n

      associate( &
           & deriv_order => this % system % get_differential_order(), &
           & a => this % A(int_order,1))
        
        forall(n=0:deriv_order)
           lincoeff(n+1) = (a/h)**n
        end forall
        
      end associate
      
    end block compute_coeffs
    
  end subroutine get_linearization_coeff

end module backward_differences_integrator_class

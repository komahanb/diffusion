#include "scalar.fpp"

!=====================================================================!
! Parent class for solving n-th order differential equations. Specific
! integrators extend this class.
!
! Author: Komahan Boopathy (komahan@gatech.edu)
!=====================================================================!

module integrator_interface

  use dynamic_physics_interface, only : dynamics

  implicit none

  private
  public ::  integrator

  type, abstract :: integrator

     !----------------------------------------------------------------!
     ! Contains the actual physical system
     !----------------------------------------------------------------!

     class(dynamics), allocatable :: system

     type(scalar)  :: tinit
     type(scalar)  :: tfinal
     type(scalar)  :: h

     !----------------------------------------------------------------!
     ! Track global time and states
     !----------------------------------------------------------------!

     type(scalar), allocatable :: time(:)  ! time values (steps)
     type(scalar), allocatable :: U(:,:,:) ! state varibles (steps, deriv_ord, nvars)

     !----------------------------------------------------------------!
     ! Variables for managing time marching
     !----------------------------------------------------------------!

     type(logical) :: implicit
     type(integer) :: num_stages
     type(integer) :: num_steps
     type(integer) :: total_num_steps

   contains

     procedure :: construct, destruct

     !----------------------------------------------------------------!
     ! Deferred procedures for subtypes to implement                  !
     !----------------------------------------------------------------!

     procedure(step_interface), deferred :: step
     procedure(get_bandwidth_interface), deferred :: get_bandwidth

     !----------------------------------------------------------------!
     ! Procedures                                                     !
     !----------------------------------------------------------------!

     procedure :: get_num_stages      , set_num_stages
     procedure :: get_num_steps       , set_num_steps
     procedure :: get_total_num_steps , set_total_num_steps     
     procedure :: is_implicit         , set_implicit     
     procedure :: set_physics

     procedure :: solve
     procedure :: write_solution
     procedure :: to_string
     
  end type integrator

  ! Define interfaces to deferred procedures
  interface

     impure subroutine step_interface(this, t, u, h, p, ierr)

       import integrator

       class(integrator) , intent(inout) :: this
       type(scalar)      , intent(inout) :: t(:)
       type(scalar)      , intent(inout) :: u(:,:,:)
       type(integer)     , intent(in)    :: p
       type(scalar)      , intent(in)    :: h
       type(integer)     , intent(out)   :: ierr

     end subroutine step_interface

     pure type(integer) function get_bandwidth_interface(this, time_index) result(width)

       import integrator

       class(integrator), intent(in) :: this
       type(integer)    , intent(in) :: time_index

     end function get_bandwidth_interface

     pure subroutine get_linearization_coeff(this, cindex, h, lincoeff)

       import integrator

       class(integrator) , intent(in)    :: this
       type(integer)     , intent(in)    :: cindex
       type(scalar)      , intent(in)    :: h
       type(scalar)      , intent(inout) :: lincoeff(:)

     end subroutine get_linearization_coeff
     
  end interface

contains
   
  !===================================================================!
  ! Base class constructor logic
  !===================================================================!

  subroutine construct(this, system, tinit, tfinal, h, implicit, num_stages)

    class(integrator) , intent(inout)         :: this
    class(dynamics)   , intent(in)   , target :: system
    type(scalar)      , intent(in)            :: tinit, tfinal
    type(scalar)      , intent(in)            :: h
    type(logical)     , intent(in)            :: implicit
    type(integer)     , intent(in)            :: num_stages

    ! Set parameters
    call this % set_physics(system)    

    this % tinit = tinit
    this % tfinal = tfinal
    this % h = h
    
    call this % set_num_steps(int((this % tfinal - this % tinit)/this % h) + 1)
    call this % set_num_stages(num_stages)
    call this % set_total_num_steps(this % get_num_steps()*(this % get_num_stages()+1) - this % get_num_stages() ) ! the initial step does not have stages
    call this % set_implicit(implicit)

  end subroutine construct

  !======================================================================!
  ! Base class destructor
  !======================================================================!

  pure subroutine destruct(this)

    class(integrator), intent(inout) :: this

    ! Clear global states and time
    if(allocated(this % U)) deallocate(this % U)
    if(allocated(this % time)) deallocate(this % time)
    if(allocated(this % system)) deallocate(this % system)
    
  end subroutine destruct

  !===================================================================!
  ! Write solution to file
  !===================================================================!

  subroutine write_solution(this, filename)

    class(integrator)             :: this
    character(len=*), intent(in)  :: filename
    character(len=7), parameter   :: directory = "output/"
    character(len=:), allocatable :: path
    character(len=:), allocatable :: new_name
    integer                       :: k, j, i, ierr
    integer                       :: nsteps

    ! Open resource
    path = trim(filename)

    open(unit=90, file=trim(path), iostat= ierr)
    if (ierr .ne. 0) then
       write(*,'("  >> Opening file ", 39A, " failed")') path
       return
    end if
    
    ! Write data
    nsteps = this % get_total_num_steps()
    loop_time: do k = 1, nsteps
       write(90, *)  this % time(k), this % U (k,:,:)
    end do loop_time
    
    ! Close resource
    close(90)

  end subroutine write_solution

  !===================================================================!
  ! Time integration logic
  !===================================================================!

  impure subroutine solve( this )
  
    class(integrator), intent(inout) :: this
    
    integer :: k, p
    integer :: ierr
    
    ! State and time history
    if (allocated(this % time)) deallocate(this%time)
    if (allocated(this % U)) deallocate(this%U)
    
    allocate(this % time( this % get_total_num_steps() ))
    this % time = 0.0d0
    
    allocate( this % U( &
         & this % get_total_num_steps(), &
         & this % system % get_differential_order() + 1, &
         & this % system % get_num_state_vars() &
         & ))
    this % U = 0.0d0   

    ! Get the initial condition
    call this % system % get_initial_condition(this % U(1,:,:))
    
    ! March in time
    time: do k = 2, this % get_total_num_steps()

       p = this % get_bandwidth(k)

       call this % step(this % time(k-p:k) , &
            & this % U(k-p:k,:,:), &
            & this % h, &
            & p, &
            & ierr)   

    end do time
    
  end subroutine solve
  
  !===================================================================!
  ! Returns the number of stages per time step
  !===================================================================!
  
  pure type(integer) function get_num_stages(this)

    class(integrator), intent(in) :: this

    get_num_stages = this % num_stages

  end function get_num_stages

  !===================================================================!
  ! Sets the number of stages per time step
  !===================================================================!

  pure subroutine set_num_stages(this, num_stages)

    class(integrator), intent(inout) :: this
    type(integer)    , intent(in)    :: num_stages

    this % num_stages = num_stages

  end subroutine set_num_stages

  !===================================================================!
  ! Returns the number of steps
  !===================================================================!

  pure type(integer) function get_num_steps(this)

    class(integrator), intent(in) :: this

    get_num_steps = this % num_steps

  end function get_num_steps

  !===================================================================!
  ! Sets the number of steps
  !===================================================================!

  pure subroutine set_num_steps(this, num_steps)

    class(integrator), intent(inout) :: this
    type(integer)    , intent(in)    :: num_steps

    this % num_steps = num_steps

  end subroutine set_num_steps

  !===================================================================!
  ! Returns the total number of steps
  !===================================================================!

  pure type(integer) function get_total_num_steps(this)

    class(integrator), intent(in) :: this

    get_total_num_steps = this % total_num_steps
    
  end function get_total_num_steps

  !===================================================================!
  ! Sets the total number of steps
  !===================================================================!

  pure subroutine set_total_num_steps(this, total_num_steps)

    class(integrator), intent(inout) :: this
    type(integer)    , intent(in)    :: total_num_steps
    
    this % total_num_steps = total_num_steps
    
  end subroutine set_total_num_steps

  !===================================================================!
  ! See if the scheme is implicit
  !===================================================================!

  pure type(logical) function is_implicit(this)

    class(integrator), intent(in) :: this

    is_implicit = this % implicit

  end function is_implicit
  
  !===================================================================!
  ! Sets the scheme as implicit
  !===================================================================!
  
  pure subroutine set_implicit(this, implicit)

    class(integrator), intent(inout) :: this
    type(logical)    , intent(in)    :: implicit

    this % implicit = implicit

  end subroutine set_implicit

  !===================================================================!
  ! Set ANY physical system that extends the type PHYSICS and provides
  ! implementation to the mandatory functions assembleResidual and
  ! getInitialStates
  !===================================================================!
  
  subroutine set_physics(this, physical_system)

    class(integrator) :: this
    class(dynamics) :: physical_system

    allocate(this % system, source = physical_system)

  end subroutine set_physics

  !===================================================================!
  ! Prints important fields of the class
  !===================================================================!
  
  subroutine to_string(this)
    
    class(integrator), intent(in) :: this
    
    print '("  >> Physical System      : " ,A10)' , this % system % get_description()
    print '("  >> Start time           : " ,F8.3)', this % tinit
    print '("  >> End time             : " ,F8.3)', this % tfinal
    print '("  >> Step size            : " ,E9.3)', this % h
    print '("  >> Number of variables  : " ,i4)'  , this % system % get_num_state_vars()
    print '("  >> Equation order       : " ,i4)'  , this % system % get_differential_order()
    print '("  >> Number of steps      : " ,i10)' , this % get_num_steps()
    print '("  >> Number of stages     : " ,i10)' , this % get_num_stages()
    print '("  >> Tot. Number of steps : " ,i10)' , this % get_total_num_steps()

  end subroutine to_string
  
end module integrator_interface

import matplotlib.pylab as plt
from mpl_toolkits.mplot3d import axes3d
import numplot.core as npl
import numpy as np

# These are the "Colors 20" colors as RGB.    
colors = [(31, 119, 180), (174, 199, 232), (255, 127, 14), (255, 187, 120),    
             (44, 160, 44), (152, 223, 138), (214, 39, 40), (255, 152, 150),    
             (148, 103, 189), (197, 176, 213), (140, 86, 75), (196, 156, 148),    
             (227, 119, 194), (247, 182, 210), (127, 127, 127), (199, 199, 199),    
             (188, 189, 34), (219, 219, 141), (23, 190, 207), (158, 218, 229)]    
  
# Scale the RGB values to the [0, 1] range, which is the format matplotlib accepts.    
for i in range(len(colors)):    
    r, g, b = colors[i]    
    colors[i] = (r / 255., g / 255., b / 255.)
    
def initcond(x):
    return ((0.4*np.pi)**(-0.5))*(np.exp(-2.5*(x-10.0)*(x-10.0))) 

def exact1(x,t, gamma=0.01):
    return (4.0*np.pi*gamma*t)**(-0.5)*np.exp(-((x-t)**2.0)/(4.0*gamma*t))

def exact2(x,t, gamma=0.01):
    return (0.4*np.pi)**(-0.5)*np.exp(-2.5*(x-t)**2.0)

def plot_space_snaps(data, sindices, xval, exact, name):
    '''
    Plot x vs u for different data sets
    '''
    
    # Plot
    plt.figure()    
    fig, ax = plt.subplots()
    ax.spines['right'].set_visible(True)
    ax.spines['top'].set_visible(True)
    ax.xaxis.set_ticks_position('bottom')
    ax.yaxis.set_ticks_position('left')   
    #ax.annotate('192,000 dof', xy=(4, 500))
    #ax.annotate('2 million dof', xy=(25, 10000))
    plt.axis([5, 45, -0.2, 1.0])
    plt.xticks(np.arange(5, 50, step=5))

    #avals = exp_euler_new['time'][250,:]
    #xvals = exp_euler_new['x'][250,:]
    
    time0 = data['time'][sindices[0], :]
    time1 = data['time'][sindices[1], :]

    print time0
    print time1
    
    #ax.annotate(('time = %gs') % time, xy=(30,0.5))
    #ax.annotate(('\Delta t = %gs') % (0.001), xy=(30,0.4))
    
    # plot solutions on same graph
    plt.plot(time0 , exact(xval[0], time0)           , '-' , lw =2, mec='black',  color=colors[6])
    plt.plot(time0 , data['state'][sindices[0],:] , '-' , lw =2, mec='black', label='x=%2gs'%(xval), color=colors[7])

    plt.plot(time1 , exact(xval[1], time1)           , '-' , lw =2, mec='black',  color=colors[8])
    plt.plot(time1 , data['state'][sindices[1],:] , '-' , lw =2, mec='black', label='x=%2gs'%(xval), color=colors[9])
    
    plt.legend(loc='upper left', framealpha=0.0)
    plt.xlabel('domain')
    plt.ylabel('solution')

    plt.savefig(name, bbox_inches='tight', pad_inches=0.05)
        
    return

def plot_time_snaps(data, tindices, exact, name):
    '''
    Plot x vs u for different data sets
    '''
    
    # Plot
    plt.figure()    
    fig, ax = plt.subplots()
    ax.spines['right'].set_visible(True)
    ax.spines['top'].set_visible(True)
    ax.xaxis.set_ticks_position('bottom')
    ax.yaxis.set_ticks_position('left')   
    #ax.annotate('192,000 dof', xy=(4, 500))
    #ax.annotate('2 million dof', xy=(25, 10000))
    plt.axis([5, 45, -0.2, 1.0])
    plt.xticks(np.arange(5, 50, step=5))
    
    x = data['x'][:,1]
    
    time0 = data['time'][1,tindices[0]]
    time1 = data['time'][1,tindices[1]]
    time2 = data['time'][1,tindices[2]]
    
    #ax.annotate(('time = %gs') % time, xy=(30,0.5))
    #ax.annotate(('\Delta t = %gs') % (0.001), xy=(30,0.4))
    
    # plot solutions on same graph
    plt.plot(x , exact(x, time0)              , '-' , lw =2, mec='black',  color=colors[0])
    plt.plot(x , data['state'][:,tindices[0]] , '-' , lw =2, mec='black', label='time=%2gs'%(time0), color=colors[1])

    plt.plot(x , exact(x, time1)              , '-' , lw =2, mec='black',  color=colors[2])
    plt.plot(x , data['state'][:,tindices[1]] , '-' , lw =2, mec='black', label='time=%2gs'%(time1), color=colors[3])

    plt.plot(x , exact(x, time2)              , '-' , lw =2, mec='black',  color=colors[4])
    plt.plot(x , data['state'][:,tindices[2]] , '-' , lw =2, mec='black', label='time=%2gs'%(time2), color=colors[5])
    
    plt.legend(loc='upper left', framealpha=0.0)
    plt.xlabel('domain')
    plt.ylabel('solution')

    plt.savefig(name, bbox_inches='tight', pad_inches=0.05)
        
    return

def plot_solution(sets, tindex, exact, name):
    '''
    Plot x vs u for different data sets
    '''
    exp_euler = sets['exp_euler']
    imp_euler = sets['imp_euler']
    cni       = sets['cni']
    
    # Plot
    plt.figure()    
    fig, ax = plt.subplots()
    ax.spines['right'].set_visible(True)
    ax.spines['top'].set_visible(True)
    ax.xaxis.set_ticks_position('bottom')
    ax.yaxis.set_ticks_position('left')   
    #ax.annotate('192,000 dof', xy=(4, 500))
    #ax.annotate('2 million dof', xy=(25, 10000))
    plt.axis([5, 45, -.1, 1.0])
    plt.xticks(np.arange(5, 50, step=5))
    
    x = exp_euler['x'][:,tindex]
    time = exp_euler_new['time'][1,tindex]
    ax.annotate(('time = %gs') % time, xy=(30,0.5))
    ax.annotate(('\Delta t = %gs') % (0.001), xy=(30,0.4))
    
    # plot solutions on same graph
    plt.plot(x, exact(x, time), '-' , lw =3, mec='black', label='analytical', color='black')
    plt.plot(exp_euler['x'][:,tindex] , exp_euler['state'][:,tindex] , '--' , lw =2,mec='black', label='explicit euler', color=colors[0], alpha=0.75)
    plt.plot(imp_euler['x'][:,tindex] , imp_euler['state'][:,tindex] , '--' , lw =2,mec='black', label='implicit euler', color=colors[2], alpha=0.75)
    plt.plot(cni['x'][:,tindex]       , cni['state'][:,tindex]       , '--' , lw =2,mec='black', label='crank nicolson', color=colors[4], alpha=0.75)
    
    plt.legend(loc='upper right')
    plt.xlabel('domain')
    plt.ylabel('solution')

    plt.savefig(name, bbox_inches='tight', pad_inches=0.05)
        
    return

def plot_history(summary, name):
    '''
    Plot ideal, total, forward and reverse modes
    '''
    jacobi = summary['jacobi']
    seidel = summary['seidel']
    sor = summary['sor']
    
    plt.figure()
    
    fig, ax = plt.subplots()
    ax.spines['right'].set_visible(True)
    ax.spines['top'].set_visible(True)
    ax.xaxis.set_ticks_position('bottom')
    ax.yaxis.set_ticks_position('left')   

    plt.loglog(jacobi['iteration'], jacobi['residual']    , '-' , lw =2, mec='black', label='jacobi', color=colors[0])
    plt.loglog(seidel['iteration'], seidel['residual'] , '-' , lw =2, mec='black', label='seidel', color=colors[2])
    plt.loglog(sor['iteration']   , sor['residual']       , '-' , lw =2, mec='black', label='sor'   , color=colors[4])

    plt.legend(loc='upper right')
    
    plt.ylabel('residual') 
    plt.xlabel('number of iterations')
    
    plt.savefig(name, bbox_inches='tight', pad_inches=0.05)
    
    return

def plot_time(summary, name):
    '''
    Plot computational time for jacobi, seidel and sor
    '''
    plt.figure()
    
    fig, ax = plt.subplots()
    ax.spines['right'].set_visible(True)
    ax.spines['top'].set_visible(True)
    ax.xaxis.set_ticks_position('bottom')
    ax.yaxis.set_ticks_position('left')   
    #plt.axis([0, 4040, 1.0e-5, 1.0e3])
                
    plt.loglog(jacobi['npts'], jacobi['wall_time'] , '-o' , lw =2, mec='black', label='jacobi', color=colors[0])
    plt.loglog(seidel['npts'], seidel['wall_time'] , '-o' , lw =2, mec='black', label='seidel', color=colors[2])
    plt.loglog(sor['npts']   , sor['wall_time']    , '-o' , lw =2, mec='black', label='sor'   , color=colors[4])
    plt.legend(loc='lower right')
    
    plt.ylabel('wall time [s]') 
    plt.xlabel('number of nodes')
    
    plt.savefig(name, bbox_inches='tight', pad_inches=0.05)
    
    return

######################################################################

# t = np.arange(10, 40, step=.1)
# plt.plot(t, exact1(15,t))
# plt.plot(t, exact1(25,t))
# plt.show()
# stop

nx = 500
ny = 3001
tindex = 0

exp_euler = npl.Map("case1-transport-explicit-euler.dat")
exp_euler_new = {}
exp_euler_new['time'] = exp_euler['time'].reshape((nx,ny))
exp_euler_new['x'] = exp_euler['x'].reshape((nx,ny))
exp_euler_new['state'] = exp_euler['state'].reshape((nx,ny))

plot_space_snaps(exp_euler_new, [125,250], [15.0, 25.0], exact1, 'case1-spacesnap-expeuler.pdf')

stop

## avals = exp_euler_new['time'][250,:]
## xvals = exp_euler_new['x'][250,:]

## #plt.plot(avals, exp_euler_new['state'][::500,:])
## #plt.show()
## print avals
## print xvals
## stop
## for aa in avals:
##     print aa



imp_euler = npl.Map("case1-transport-implicit-euler.dat")
imp_euler_new = {}
imp_euler_new['time'] = imp_euler['time'].reshape((nx,ny))
imp_euler_new['x'] = imp_euler['x'].reshape((nx,ny))
imp_euler_new['state'] = imp_euler['state'].reshape((nx,ny))

cni = npl.Map("case1-transport-cni.dat")
cni_new = {}
cni_new['time'] = cni['time'].reshape((nx,ny))
cni_new['x'] = cni['x'].reshape((nx,ny))
cni_new['state'] = cni['state'].reshape((nx,ny))

solutions = {}
solutions['exp_euler'] = exp_euler_new
solutions['imp_euler'] = imp_euler_new
solutions['cni'] = cni_new

#plot_solution(solutions, tindex, exact1, 'linear_solution.pdf')

# Case 1
#plot_time_snaps(exp_euler_new, [1000,2000,3000], exact1, 'case1-timesnaps-expeuler.pdf')
#plot_time_snaps(imp_euler_new, [1000,2000,3000], exact1, 'case1-timesnaps-impeuler.pdf')
#plot_time_snaps(cni_new      , [1000,2000,3000], exact1, 'case1-timesnaps-cni.pdf')


plot_space_snaps(imp_euler_new, [125,250], [15.0, 25.0], exact1, 'case1-spacesnap-impeuler.pdf')
plot_space_snaps(cni_new      , [125,250], [15.0, 25.0], exact1, 'case1-spacesnap-cni.pdf')

stop

# Case 2
exp_euler = npl.Map("case2-transport-explicit-euler.dat")
exp_euler_new = {}
exp_euler_new['time'] = exp_euler['time'].reshape((nx,ny))
exp_euler_new['x'] = exp_euler['x'].reshape((nx,ny))
exp_euler_new['state'] = exp_euler['state'].reshape((nx,ny))

imp_euler = npl.Map("case2-transport-implicit-euler.dat")
imp_euler_new = {}
imp_euler_new['time'] = imp_euler['time'].reshape((nx,ny))
imp_euler_new['x'] = imp_euler['x'].reshape((nx,ny))
imp_euler_new['state'] = imp_euler['state'].reshape((nx,ny))

cni = npl.Map("case2-transport-cni.dat")
cni_new = {}
cni_new['time'] = cni['time'].reshape((nx,ny))
cni_new['x'] = cni['x'].reshape((nx,ny))
cni_new['state'] = cni['state'].reshape((nx,ny))

solutions = {}
solutions['exp_euler'] = exp_euler_new
solutions['imp_euler'] = imp_euler_new
solutions['cni'] = cni_new

# Case 2
#plot_time_snaps(exp_euler_new, [1000,2000,3000], exact2, 'case2-timesnaps-expeuler.pdf')
#plot_time_snaps(imp_euler_new, [1000,2000,3000], exact2, 'case2-timesnaps-impeuler.pdf')
#plot_time_snaps(cni_new      , [1000,2000,3000], exact2, 'case2-timesnaps-cni.pdf')

stop

Z = jacobi['T'].reshape((nx,ny))

fig = plt.figure()
ax = fig.add_subplot(111, projection="3d")

## plt.contour(X,Y,Z)
## plt.xlabel("x")
## plt.ylabel("y")
## plt.show()
## stop

ax.plot_surface(X, Y, Z, cmap="autumn_r", lw=0.5, rstride=1, cstride=1)
#ax.contour(X, Y, Z, 10, lw=3, cmap="autumn_r", linestyles="solid", offset=-1)
#ax.contour(X, Y, Z, 10, lw=3, colors="k", linestyles="solid")
ax.set_xlabel("X")
ax.set_ylabel("Y")
ax.set_zlabel("T")
plt.show()
stop

sol20 = npl.Map("linear-solution-npts-20.dat")
sol30 = npl.Map("linear-solution-npts-30.dat")
sol40 = npl.Map("linear-solution-npts-40.dat")
sol50 = npl.Map("linear-solution-npts-50.dat")

solution = {}
solution['sol10'] = sol10
solution['sol20'] = sol20
solution['sol30'] = sol30
solution['sol40'] = sol40
solution['sol50'] = sol50
plot_solution(solution, 'linear_solution.pdf')

linear_summary = npl.Map("linear_summary.dat")
nonlinear_summary1 = npl.Map("nonlinear_summary-case-1.dat")
nonlinear_summary2 = npl.Map("nonlinear_summary-case-2.dat")
nonlinear_summary3 = npl.Map("nonlinear_summary-case-3.dat")

# plot nonlinear solutions vs x
nonsol1 =  npl.Map("nonlinear-solution-npts-20-case-1.dat")
nonsol2 =  npl.Map("nonlinear-solution-npts-20-case-2.dat")
nonsol3 =  npl.Map("nonlinear-solution-npts-20-case-3.dat")
plot_nonlinear_solution(nonsol1, 'nonlinear_solution-case1.pdf')
plot_nonlinear_solution(nonsol2, 'nonlinear_solution-case2.pdf')
plot_nonlinear_solution(nonsol3, 'nonlinear_solution-case3.pdf')

stop
import numpy as np

# Simple select (replacement for numpy.select) v2.0

# Graeme B Bell, Norwegian Forest & Landscape Institute. grb@skogoglandskap.no

# CHANGELOG
#
# v2.0
# 1. simplified code, added full broadcasting. 
# 2. faster than v1.0, less code to verify, fully backwards compatible.
# 3. scalar execution path around 5x faster than np.select
# 4. broadcast execution path generally 2-3x faster than np.select
#
# v1.0
# 1. Fixes two bugs (ARG_MAX 32 limit, return value/type for input of ([],[]))
# 2. Improved detection of bad input parameters.
# 3. Faster than np.select when given scalar condlist parameters. 
# 4. Similar or slightly slower where condlist are equally shaped ndarrays.
# 5. Slower for mixed scalar/ndarray condlist.
# 6. Does not support advanced broadcasting in condlist/choicelist, only scalar/one size ndarray.
#    (how many use cases actually need this?)
# 7. Improved internal documentation.
# 8. The function description is derived from numpy.select()

def select(condlist, choicelist, default=0):
    """
    Return an array drawn from elements in choicelist, depending on conditions.

    Parameters
    ----------
    condlist : list of bool ndarrays
        The list of conditions which determine from which array in `choicelist`
        the output elements are taken. When multiple conditions are satisfied,
        the first one encountered in `condlist` is used.
    choicelist : list of ndarrays and/or scalars.
        The list of arrays from which the output elements are taken. It has
        to be of the same length as `condlist`.
    default : scalar, optional
        The element inserted in `output` when all conditions evaluate to False.

    Returns
    -------
    output : ndarray
        The output at position m is the m-th element of the array in
        `choicelist` where the m-th element of the corresponding array in
        `condlist` is True.

    See Also
    --------
    numpy.select : Original version in numpy. 
    numpy.where : Return elements from one of two arrays depending on condition.
    numpy.take, numpy.choose, numpy.compress, numpy.diag, numpy.diagonal

    Examples
    --------
    >>> x = np.arange(10)
    >>> condlist = [x<3, x>5]
    >>> choicelist = [x, x**2]
    >>> ss.select(condlist, choicelist)
    array([ 0,  1,  2,  0,  0,  0, 36, 49, 64, 81])

    """

    # Clone the input lists to prevent side effects to the parameter lists:
    condlist = list(condlist)
    choicelist = list(choicelist)

    # Check that the inputs are acceptable.

    # Check the size of condlist and choicelist are the same, or abort.
    if len(condlist) != len(choicelist):
        raise ValueError('list of cases must be same length as list of conditions')

    # If condlist/choicelist are empty, return the default value immediately.
    if len(condlist)==0:
        return np.array([]) 

    # If cond array is not an ndarray in boolean format or scalar bool, abort.
    deprecated_ints=False    
    for i in range(0,len(condlist)):
        item=np.asarray(condlist[i])
        if item.dtype != np.bool_:
            if np.issubdtype(item.dtype, np.int_):
                # A previous implementation accepted int ndarrays accidentally.
                # Supported here deliberately, but deprecated and to be removed.
                condlist[i]=condlist[i].astype(bool)
                deprecated_ints=True
            else:
                raise ValueError('invalid entry in choice array: should be boolean ndarray')

    # Create dictionaries noting the sizes of the items in the lists. 
    cond_sizes = {} ; choice_sizes = {}    

    for i in range(0,len(condlist)):
        if type(condlist[i]) is np.ndarray:
            cond_sizes[condlist[i].shape]=True 
        else:
            cond_sizes['scalar bool']=True

    for i in range(0,len(choicelist)):
        if type(choicelist[i]) is np.ndarray:
            choice_sizes[choicelist[i].shape]=True 
     
    sizes=cond_sizes.copy() 
    sizes.update(choice_sizes)

    # Test for ndarrays with no data.
    if (0,) in sizes.keys():
        raise ValueError('ndarray containing no items is present')

    # If there is more than one size of array in condlist, we should broadcast them now.
    # (I am not sure if this is useful/meaningful, I will leave it to the user to find a use case). 
    if len(cond_sizes.keys())>1:
        condlist=np.broadcast_arrays(*condlist)

    # Reverse the lists to put lowest priority (end of condlist) conditions at the beginning.
    # This is so the low priority values are overwritten during successive stages of burning values through masks.
    condlist.reverse()
    choicelist.reverse()

    # Super-fast execution path if there are only scalar values in the choice list (common use case)
    # Generate array; iteratively burn values onto result using simple boolean indexing; return. 

    if len(choice_sizes.keys())==0:
        result=np.ones_like(condlist[0])*default      
        for i in range(0,len(condlist)):    
            result[condlist[i]]=choicelist[i]
        return result

    # otherwise, we have to broadcast    
    # for numpy 1.7, you have to broadcast the indexes by hand. numpy 1.6 did it automatically, I think?

    to_broadcast = condlist + choicelist      # make into a single big list
    bc=np.broadcast_arrays(*to_broadcast)     # unpack values from big list and broadcast them
    condlist=bc[:len(bc)/2]                   # split the bc'd big list back into 2 parts again
    choicelist=bc[len(bc)/2:]                 # down the middle
   
    # Setup an array filled with default values
    result=np.ones_like(condlist[0])*default      

    # Use numpy boolean addressing to burn each choicelist array onto result, 
    # using the corresponding condlist as a boolean mask 
    # Doing it this way is several times faster than e.g. numpy.where.
    for i in range(0,len(condlist)):
         result[condlist[i]]=(choicelist[i])[condlist[i]]

    return result

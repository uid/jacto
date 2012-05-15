package edu.mit.csail.uid.jacto;

import java.io.IOException;
import java.io.PrintWriter;
import java.lang.reflect.*;
import java.net.Socket;

import org.aspectj.lang.reflect.*;

/**
 * Observes methods called during execution of JUnit tests and reports via a
 * local socket.
 */
aspect Jacto {
    
    static final PrintWriter out;
    
    static {
        PrintWriter p;
        try {
            int port = Integer.parseInt(System.getenv("JACTO_PORT"));
            p = new PrintWriter(new Socket("localhost", port).getOutputStream(), true);
        } catch (Exception e) {
            e.printStackTrace(); // XXX
            p = new PrintWriter(System.err, true);
        }
        out = p;
    }
    
    static void test(MethodSignature sig) {
        out.println("test " + sig.getDeclaringTypeName() + " " + sig.getName());
    }
    
    static void call(ConstructorSignature sig) {
        call(sig, sig.getConstructor().getGenericParameterTypes());
    }
    
    static void call(MethodSignature sig) {
        call(sig, sig.getMethod().getGenericParameterTypes());
    }
    
    static void call(CodeSignature sig, Type[] parameterTypes) {
        out.print("call " + sig.getDeclaringTypeName() + " " + sig.getName() + " ");
        for (Type type : parameterTypes) {
            out.print(typeName(type) + " ");
        }
        out.println();
    }
    
    static String typeName(Type type) {
        if (type instanceof Class) {
            return ((Class<?>)type).getCanonicalName();
        } else if (type instanceof GenericArrayType) {
            return "UNKNOWN_GENERIC_ARRAY_TYPE";
        } else if (type instanceof ParameterizedType) {
            return typeName(((ParameterizedType)type).getRawType());
        } else if (type instanceof TypeVariable) {
            return ((TypeVariable<?>)type).getName();
        } else if (type instanceof WildcardType) {
            return "UNKNOWN_WILDCARD_TYPE";
        } else {
            return "UNKNOWN_TYPE";
        }
    }
    
    pointcut testing() : execution(@org.junit.Test void *(..));
    pointcut constructor() : execution(new(..));
    pointcut method() : execution(* *(..));
    
    before() : testing() {
        test((MethodSignature)thisJoinPointStaticPart.getSignature());
    }
    
    before() : cflowbelow(testing()) && constructor() && ! within(Jacto) {
        call((ConstructorSignature)thisJoinPointStaticPart.getSignature());
    }
    
    before() : cflowbelow(testing()) && method() && ! within(Jacto) {
        call((MethodSignature)thisJoinPointStaticPart.getSignature());
    }
    
}
